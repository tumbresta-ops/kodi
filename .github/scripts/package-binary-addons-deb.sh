#!/usr/bin/env bash

set -euo pipefail

kodi_dir=${1:?Usage: package-binary-addons-deb.sh <kodi-dir> <install-prefix> <output-dir>}
install_prefix=${2:?Usage: package-binary-addons-deb.sh <kodi-dir> <install-prefix> <output-dir>}
output_dir=${3:?Usage: package-binary-addons-deb.sh <kodi-dir> <install-prefix> <output-dir>}

status_file="${kodi_dir}/cmake/addons/.success"
if [[ ! -s "${status_file}" ]]; then
  echo "::error::No successful binary add-on build list found: ${status_file}"
  exit 1
fi

kodi_major=$(sed -n 's/^VERSION_MAJOR[[:space:]]*//p' "${kodi_dir}/version.txt")
if [[ ! "${kodi_major}" =~ ^[0-9]+$ ]]; then
  echo "::error::Could not determine Kodi major version from ${kodi_dir}/version.txt"
  exit 1
fi

architecture=$(dpkg --print-architecture)
mkdir -p "${output_dir}"

while IFS= read -r addon_id; do
  [[ -n "${addon_id}" ]] || continue
  if [[ ! "${addon_id}" =~ ^[a-z0-9][a-z0-9.+-]*$ ]]; then
    echo "::error::Invalid add-on ID in build status: ${addon_id}"
    exit 1
  fi

  addon_data="${install_prefix}/share/kodi/addons/${addon_id}"
  addon_binary="${install_prefix}/lib/kodi/addons/${addon_id}"
  addon_xml="${addon_data}/addon.xml"

  if [[ ! -f "${addon_xml}" ]]; then
    echo "::error::Built add-on metadata is missing: ${addon_xml}"
    exit 1
  fi

  addon_version=$(python3 - "${addon_xml}" "${addon_id}" <<'PY'
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
if root.get("id") != sys.argv[2]:
    raise SystemExit(f"add-on ID mismatch in {sys.argv[1]}")
version = root.get("version")
if not version:
    raise SystemExit(f"missing add-on version in {sys.argv[1]}")
print(version)
PY
)
  if ! dpkg --validate-version "${addon_version}"; then
    echo "::error::Invalid Debian package version for ${addon_id}: ${addon_version}"
    exit 1
  fi

  package_root=$(mktemp -d)
  trap 'rm -rf "${package_root}"' EXIT
  mkdir -p "${package_root}/DEBIAN"
  chmod 0755 "${package_root}"

  if [[ -d "${addon_binary}" ]]; then
    mkdir -p "${package_root}/usr/lib/kodi/addons/${addon_id}"
    cp -a "${addon_binary}/." "${package_root}/usr/lib/kodi/addons/${addon_id}/"
  fi
  mkdir -p "${package_root}/usr/share/kodi/addons/${addon_id}"
  cp -a "${addon_data}/." "${package_root}/usr/share/kodi/addons/${addon_id}/"

  cat > "${package_root}/DEBIAN/control" <<EOF
Package: kodi-${addon_id}
Version: ${addon_version}
Section: video
Priority: optional
Architecture: ${architecture}
Depends: kodi-bin (>= 2:${kodi_major}.0), kodi-bin (<< 2:$((kodi_major + 1)).0)
Maintainer: Kodi Kademlia Build <noreply@kodi.tv>
Description: Kodi binary add-on ${addon_id}
 Binary add-on built for Kodi ${kodi_major}.x.
EOF

  package_path="${output_dir}/kodi-${addon_id}_${addon_version}_${architecture}.deb"
  dpkg-deb --build --root-owner-group "${package_root}" "${package_path}"
  rm -rf "${package_root}"
  trap - EXIT
  echo "Created ${package_path}"
done < "${status_file}"
