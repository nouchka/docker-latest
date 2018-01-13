#!/bin/bash
# FROM https://raw.githubusercontent.com/jessfraz/dockerfiles/f59c31059a0e15280ba4bec5ecfd912a71ca8864/latest-versions.sh
# This script gets the latest GitHub releases for the specified projects.
set -e
set -o pipefail

if [[ -z "$GITHUB_TOKEN" ]]; then
	echo "Set the GITHUB_TOKEN env variable."
	exit 1
fi

URI=https://api.github.com
API_VERSION=v3
API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

get_latest() {
	local dockerfile=$1
	local repo=$(cat "${dockerfile}" | grep -m 1 REPOSITORY | awk '{print $(NF)}'|awk -F= '{print $(NF)}')
	local current=$(cat "${dockerfile}" | grep -m 1 VERSION | awk '{print $(NF)}'|awk -F= '{print $(NF)}')
	local sha=$(cat "${dockerfile}" | grep -m 1 FILE_SHA256SUM | awk '{print $(NF)}'|awk -F= '{print $(NF)}')
	local url=$(cat "${dockerfile}" | grep -m 1 FILE_URL | awk '{print $(NF)}')
	local tag_strip=$(cat "${dockerfile}" | grep -m 1 TAG_STRIP | awk '{print $(NF)}')

	local resp=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${repo}/releases/latest")
	local tag=$(echo $resp | jq -e --raw-output .tag_name)
	local name=$(echo $resp | jq -e --raw-output .name)

	if [[ "$tag" == "null" ]]; then
		# get the latest tag
		local resp=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${repo}/tags")
		local tag=$(echo $resp | jq -e --raw-output .[0].name)
		tag=${tag#release-}
	fi

	if [[ "$name" == "null" ]] || [[ "$name" == "" ]]; then
		name="-"
	fi

	local dir=${repo#*/}

	if [[ "$tag" =~ "$current" ]] || [[ "$name" =~ "$current" ]] || [[ "$current" =~ "$tag" ]] || [[ "$current" == "master" ]]; then
		echo -e "\e[36m${dir}:\e[39m current ${current} | ${tag} | ${name}"
	else
		# add to the bad versions
		bad_versions+=( "${dir}" )
		echo -e "\e[31m${dir}:\e[39m current ${current} | ${tag} | ${name} | https://github.com/${repo}/releases"
		local VERSION=$(echo $tag|sed "s/$tag_strip//g")
		local REPOSITORY=${repo}
		url=$(eval echo $url)
		curl -L ${url} > /tmp/dl.file
		sha256sum /tmp/dl.file
	fi
}

bad_versions=()

main() {
	find /root/latest/ -type f -name Dockerfile| while read dockerfile
	do
		get_latest "$dockerfile"
	done

	if [[ ${#bad_versions[@]} -ne 0 ]]; then
		echo
		echo "These Dockerfiles are not up to date: ${bad_versions[@]}" >&2
		exit 1
	fi
}

main
