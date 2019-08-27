#!/bin/bash

## todo: Add SSL support (certificate for browser)
## todo: Update README.md
## todo: elasticsearch requirement on host: sudo sysctl -w vm.max_map_count=262144

## Disclaimer if not launch from Ubuntu

UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
if [[ ! "$DISTRO" == "Ubuntu" ]]; then
    echo "Disclaimer: Welcome $DISTRO user. FYI, this Docker stack has only been Tested on Ubuntu..."
fi

## Test and import .env file

if [[ -f .env ]]
then
    export $(cat .env | sed 's/#.*//g' | xargs)
else
    echo "ERROR: .env file is missing. Please review the .env.dist file for a template."
    exit 1
fi

## test /etc/hosts

if ! grep --quiet ${MAGENTO_BASE_URL} /etc/hosts; then
  echo "Host $MAGENTO_BASE_URL is not defined in your /etc/hosts file"
  exit
fi

## Test if the targetted user is in www-data group

if ! groups ${USER_NAME} | grep &>/dev/null '\bwww-data\b'; then
    echo "Error: $USER_NAME user is not a member of the www-data group"
    exit 1
fi

## Check and copy the Composer auth.json file

if [[ "$MAGENTO_PUBLIC_KEY" == "your_public_key" ]]; then
    echo "MAGENTO_PUBLIC_KEY or MAGENTO_PRIVATE_KEY are not valid in your .env file."
    echo "Please visit https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html for more info."
    exit 1
fi
cp ./apache2/auth.json.template ./apache2/auth.json
sed -i "s/MAGENTO_PUBLIC_KEY/$MAGENTO_PUBLIC_KEY/g" ./apache2/auth.json
sed -i "s/MAGENTO_PRIVATE_KEY/$MAGENTO_PRIVATE_KEY/g" ./apache2/auth.json

## Check existing Magento2 Folder, Create one if none exists

if [[ ! -d ${MAGENTO_BASE_FOLDER} ]]
then
    mkdir ${MAGENTO_BASE_FOLDER}
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Enable to create $MAGENTO_BASE_FOLDER."
        exit 1
    fi
fi

## Compile & Launch the Docker stack

docker-compose up -d
if [[ $? -ne 0 ]]; then
	echo "ERROR: An error occurred while launching the docker stack."
	exit 1
fi
