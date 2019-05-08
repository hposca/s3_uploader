#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

s3_endpoint="http://localhost:4572"
bucket="development"
application_url="http://localhost:5000"
filename="tux.svg"

echo "Waiting for services to become available..."
until $(curl --output /dev/null --silent --fail --head "${application_url}"); do
  echo '...'
  sleep 2
done

echo ""

aws --endpoint-url="${s3_endpoint}" s3api create-bucket --bucket "${bucket}"

curl -F "file_to_upload=@${DIR}/${filename}" "${application_url}/upload/"

# To delete the file:
# aws --endpoint-url="${s3_endpoint}" s3 rm s3://${bucket}/${filename}
