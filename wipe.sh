#!/bin/bash

#INPUT
DIRECTORY_TO_BACKUP=
S3CMD_CONFIG=

if [[ $# -lt 1 ]]
then
    echo "Missing parameters, please use ${0} --help"
    exit 1
fi

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --directory-to-backup)
    DIRECTORY_TO_BACKUP="${2}"
    shift
    shift
    ;;
    --s3cmd-config)
    S3CMD_CONFIG="${2}"
    shift
    shift
    ;;
    --help)
    echo "$0"
    echo " --directory-to-backup DIRECTORY_TO_BACKUP"
    echo " --s3-cmd S3CMD_CONFIG"
    exit 0
    ;;
    *)
    echo "Unknown parameter ${1}, please use ${0} --help"
    exit 1
    ;;
esac
done

if [ -z "${DIRECTORY_TO_BACKUP}" ]
then
	echo "Missing directory to backup, please use ${0} --help"
	exit 1
fi

if [ -z "${S3CMD_CONFIG}" ]
then
	echo "Missing s3cmd config, please use ${0} --help"
	exit 1
fi

#INIT DATA
echo "== Initialisating data"

HASH_PATH=$(echo "${DIRECTORY_TO_BACKUP}" | /usr/bin/openssl sha1 | /usr/bin/awk '{print $2;}')

echo "- Hash path: ${HASH_PATH}"

#CHECK BACKUP
echo "== Checking for an existing backup"

EXISTS_BACKUP_DIRECTORY=$(s3cmd ls -c ${S3CMD_CONFIG} s3://dyser-data 2>/dev/null | grep ${HASH_PATH})

if [ -z "${EXISTS_BACKUP_DIRECTORY}" ]
then
	echo "- there backup does not exists, please check the path."
else
	echo "== Deleting files of the backup"
	s3cmd rm -c ${S3CMD_CONFIG} -r s3://dyser-data/${HASH_PATH} 2>/dev/null

fi
