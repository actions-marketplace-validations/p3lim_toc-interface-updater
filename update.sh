#!/bin/bash

[[ -z "$CF_API_KEY" ]] && {
	echo "Missing CF_API_KEY"
	exit 1
}
[[ -z "$WOWI_API_TOKEN" ]] && {
	echo "Missing WOWI_API_TOKEN"
	exit 1
}

gameVersions="$(curl -sSLH"X-API-Token: $CF_API_KEY" "https://wow.curseforge.com/api/game/versions")"
if jq '.errorCode' <<< "$gameVersions"; then
	# if this doesn't fail then we have an error
	echo "Error: $(jq -r '.errorMessage' <<< "$gameVersions")"
	exit 1
elif [[ -z "$gameVersions" ]]; then
	echo "Error: no data from CurseForge API"
	exit 1
fi

retailVersion="$(jq -r 'map(select(.gameVersionTypeID == 517)) | max_by(.id) | .name' <<< "$gameVersions")"
classicVersion="$(jq -r 'map(select(.gameVersionTypeID == 67408)) | max_by(.id) | .name' <<< "$gameVersions")"

if [[ -z "$retailVersion" ]] || [[ -z "$classicVersion" ]]; then
	echo "Failed to get game version from CurseForge"
	exit 1
fi

interfaceVersions="$(curl -sSLH"X-API-Token: $WOWI_API_TOKEN" "https://api.wowinterface.com/addons/compatible.json")"
if jq '.ERROR' <<< "$interfaceVersions"; then
	# if this doesn't fail then we have an error
	echo "Error: $(jq -r '.ERROR' <<< "$interfaceVersions")"
	exit 1
elif [[ -z "$interfaceVersions" ]]; then
	echo "Error: no data from WoWInterface API"
	exit 1
fi

retailInterfaceVersion="$(jq -r '.[] | select(.id == "'"$retailVersion"'") | .interface' <<< "$interfaceVersions")"
classicInterfaceVersion="$(jq -r '.[] | select(.id == "'"$classicVersion"'") | .interface' <<< "$interfaceVersions")"

if [[ -z "$retailInterfaceVersion" ]] || [[ -z "$classicInterfaceVersion" ]]; then
	echo "Failed to get interface version from WoWInterface"
	exit 1
fi

while read -r file; do
	# TODO: check/output if we actully made any changes
	sed -ri 's/^(## Interface: ).*$/\1'"$retailInterfaceVersion"'/' "$file"
	sed -ri 's/^(## Interface-Retail: ).*$/\1'"$retailInterfaceVersion"'/' "$file"
	sed -ri 's/^(## Interface-Classic: ).*$/\1'"$classicInterfaceVersion"'/' "$file"
done < <(find . -name '*.toc')