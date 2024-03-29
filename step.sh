#!/bin/bash

set -o pipefail

echo "Instabug mapping file uploader"

echo "Build gradle path $build_gradle_path"

if [ ! -f $build_gradle_path ]; then
    echo "build.gradle file not found. Might be the wrong path or you're running the step before clonning the project."
    exit 1
fi

# Extract versionCode and versionName from build.gradle file.
VERSION_CODE=$(awk '/defaultConfig/,/versionCode/ {if ($1 == "versionCode") print $2}' $build_gradle_path | tr -d " ")
VERSION_NAME=$(awk -F '"' '/versionName/ {print $2}' $build_gradle_path)

echo "Version Code: $VERSION_CODE"

envman add --key VERSION_CODE --value $VERSION_CODE

echo "Version Name: $VERSION_NAME"

envman add --key VERSION_NAME --value $VERSION_NAME

VERSION='{"code":"'"$VERSION_CODE"'","name":"'"$VERSION_NAME"'"}'

if [ ! -f $BITRISE_MAPPING_PATH ]; then
    echo "Mapping file not found. Did you run this step before the build step?"
    exit 1
fi

echo "Mapping file found! Uploading..."

ENDPOINT="https://api.instabug.com/api/sdk/v3/symbols_files"

STATUS=$(curl "${ENDPOINT}" --write-out %{http_code} --silent --output /dev/null -F os=android -F app_version="${VERSION}" -F symbols_file=@"${BITRISE_MAPPING_PATH}" -F application_token="${instabug_app_token}")

if [ $STATUS -ne 200 ]; then
  echo "Error while uploading mapping file"
  exit 1
fi

echo "Success! Your mapping file got uploaded successfully"

exit 0



