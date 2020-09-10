#!/bin/bash

#INPUT
BACKUP_NAME=
RECTORE_TO_DIRECTORY=
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
    --restore-to-directory)
    RESTORE_TO_DIRECTORY="${2}"
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
    echo " --backup-name BACKUP_NAME"
    echo " --restore-to-directory RESTORE_TO_DIRECTORY"
    echo " --s3cmd-config S3CMD_CONFIG"
    echo " --bucket-name BUCKET_NAME"
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

if [ -z "${RESTORE_TO_DIRECTORY}" ]
then
	echo "Missing restore to directory, please use ${0} --help"
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
	exit 1
fi

echo "== Initialisating data"

HASH_PATH=$(echo "${BACKUP_NAME}" | /usr/bin/openssl sha1 | /usr/bin/awk '{print $2;}')

echo "- Hash path: ${HASH_PATH}"

echo "== Creating temporary directory"

TEMPORARY_DIRECTORY=tmp/$(date +"%T" | md5sum | awk '{print $1}')

mkdir -p ${TEMPORARY_DIRECTORY}

echo "- Temporary directory: ${TEMPORARY_DIRECTORY}"

echo "== Checking backup"
EXISTS_BACKUP_DIRECTORY=$(s3cmd ls -c ${S3CMD_CONFIG} s3://${BUCKET_NAME} 2>/dev/null | grep ${HASH_PATH})

if [ -z "${EXISTS_BACKUP_DIRECTORY}" ]
then
	echo "This backup does not exists."
	exit 1
fi

echo "== Downloading file list"
s3cmd get -c ${S3CMD_CONFIG} s3://${BUCKET_NAME}/${HASH_PATH}/files.list.enc "${TEMPORARY_DIRECTORY}" 2>/dev/null
openssl enc -d -aes-256-cbc -salt -pbkdf2 -a -kfile password -in "${TEMPORARY_DIRECTORY}/files.list.enc" -out "${TEMPORARY_DIRECTORY}/files.list"

echo "== Downloading backup"

cat "${TEMPORARY_DIRECTORY}/files.list" | while read line
do
	echo "- downloading file"

	file_name=$(echo "${line}" | cut -d"|" -f1)
	file_path=$(echo "${line}" | cut -d"|" -f2)
	path_only=$(echo "${file_path}" | sed "s/\/$(echo "${file_path}" | rev | cut -d"/" -f1 | rev)//g")
	file_info=$(echo "${line}" | cut -d"|" -f3)
	file_destination=${RESTORE_TO_DIRECTORY}/${file_path}

	echo " - extracting file at: s3://${BUCKET_NAME}/${HASH_PATH}/${file_name}"
	echo " - creating path: ${path_only}"
	echo " - downloading to: ${file_destination}"
	echo " - using information: ${file_info}"

	mkdir -p ${RESTORE_TO_DIRECTORY}/${path_only}

	s3cmd get -c ${S3CMD_CONFIG} s3://${BUCKET_NAME}/${HASH_PATH}/${file_name} "${TEMPORARY_DIRECTORY}/${file_name}"
	openssl enc -d -aes-256-cbc -salt -pbkdf2 -a -kfile password -in "${TEMPORARY_DIRECTORY}/${file_name}" -out "${file_destination}"

	#chown "${file_destination}"
	#chmod "${file_destination}"
done

echo "== Removing temporary directory"
rm -rf ${TEMPORARY_DIRECTORY}

echo "Done!"
