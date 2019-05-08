#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

application_url="http://${LOAD_BALANCER}"
filename="tux.svg"

curl -F "file_to_upload=@${DIR}/${filename}" "${application_url}/upload/"
