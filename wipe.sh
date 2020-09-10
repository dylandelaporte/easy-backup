#!/bin/bash

#INPUT
BACKUP_NAME=
S3CMD_CONFIG=
BUCKET_NAME=

if [[ $# -lt 1 ]]
then
    echo "Missing parameters, please use ${0} --help"
    exit 1
fi

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --backup-name)
    BACKUP_NAME="${2}"
    shift
    shift
    ;;
    --s3cmd-config)
    S3CMD_CONFIG="${2}"
    shift
    shift
    ;;
    --bucket-name)
    BUCKET_NAME="${2}"
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

if [ -z "${BACKUP_NAME}" ]
then
	echo "Missing backup name, please use ${0} --help"
	exit 1
fi

if [ -z "${S3CMD_CONFIG}" ]
then
	echo "Missing s3cmd config, please use ${0} --help"
	exit 1
fi

if [ -z "${BUCKET_NAME}" ]
then
	echo "Missing bucket name, please use ${0} --help"
fi

#INIT DATA
echo "== Initialisating data"

HASH_PATH=$(echo "${BACKUP_NAME}" | /usr/bin/openssl sha1 | /usr/bin/awk '{print $2;}')

echo "- Hash path: ${HASH_PATH}"

#CHECK BACKUP
echo "== Checking for an existing backup"

EXISTS_BACKUP_DIRECTORY=$(s3cmd ls -c ${S3CMD_CONFIG} s3://${BUCKET_NAME} 2>/dev/null | grep ${HASH_PATH})

if [ -z "${EXISTS_BACKUP_DIRECTORY}" ]
then
	echo "- there backup does not exists, please check the path."
else
	echo "== Deleting files of the backup"
	s3cmd rm -c ${S3CMD_CONFIG} -r s3://${BUCKET_NAME}/${HASH_PATH} 2>/dev/null

fi
