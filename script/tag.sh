#!/usr/bin/env bash

set -e -u

SCRIPT_NAME=$(basename "$0")

MB_SERVER_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)
source "$MB_SERVER_ROOT"/script/macos_compat.inc.sh

HELP=$(cat <<EOH
Usage: $SCRIPT_NAME

Create and push a Git tag on 'production' branch.
EOH
)

if [ $# -eq 1 ] && echo "$1" | grep -Eqx -- '-*h(elp)?'
then
  echo "$HELP"
  exit
elif [ $# -gt 0 ]
then
  echo >&2 "$SCRIPT_NAME: too many arguments"
  echo >&2 "$HELP"
  exit 64
fi

if ! (git diff --quiet && git diff --cached --quiet)
then
  echo >&2 "$SCRIPT_NAME: Git working tree has local changes"
  echo >&2
  echo >&2 "Your local changes might be missing from 'production' branch."
  echo >&2 "Please clean your Git working tree before tagging 'production'."
  exit 70
fi

year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)

today_version_prefix="v-$year-$month-$day"
today_versions_count=$(git tag -l "${today_version_prefix}*" | wc -l | sed 's/\s//g')
tag="${today_version_prefix}.${today_versions_count}"
read -e -i "$tag" -p 'Tag? ' -r tag

jira_versions_json=$(curl -sS 'https://tickets.metabrainz.org/rest/api/2/version?projectIds=10000')
jira_last_unreleased_version_json=$(echo "$jira_versions_json" | jq -r '.values|.[]|=select(.released==false)|sort_by(.id)|.[-1]')
jira_version_serial=$(echo "$jira_last_unreleased_version_json" | jq -r .id)

cat <<EOV
Last unreleased version in Jira:
  - Serial ID: $jira_version_serial
  - Name: $(echo "$jira_last_unreleased_version_json" | jq -r .name)
  - Description: $(echo "$jira_last_unreleased_version_json" | jq -r .description)
EOV

jira_version_url="https://tickets.metabrainz.org/projects/MBS/versions/$jira_version_serial"
read -e -i "$jira_version_url" -p 'Jira version URL? ' -r jira_version_url

set -x
git tag -u CE33CF04 "$tag" -m "See $jira_version_url for details" production
git push origin "$tag"

# vi: set et sts=2 sw=2 ts=2 :
