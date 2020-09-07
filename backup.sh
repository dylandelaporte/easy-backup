#!/bin/bash

#INPUT
DIRECTORY_TO_BACKUP=
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

if [ -z "${BUCKET_NAME}" ]
then
	echo "Missing bucket name, please use ${0} --help"
	exit 1
fi

#INIT DATA
echo "== Initialisating data"

HASH_PATH=$(echo "${DIRECTORY_TO_BACKUP}" | /usr/bin/openssl sha1 | /usr/bin/awk '{print $2;}')
FILES=$(/usr/bin/find "${DIRECTORY_TO_BACKUP}" -type f -exec /bin/ls -l --full-time {} \;)
COUNT_FILES=$(echo "${FILES}" | wc -l)

echo "- Hash path: ${HASH_PATH}"
echo "- Count files: ${COUNT_FILES}"

#refreshing tmp dir
echo "== Refreshing temporary directory"
rm -rf tmp
mkdir tmp

#preparing files
echo "== Preparing files"

echo "${FILES}" | while read line
do
	file_path=$(echo "${line}" | awk 'BEGIN {ORS=""}; {for(i=9;i<=NF;i++) print $i " "}; {print "\n"};')
	
	if [ -n "$file_path" ]
	then
		echo "- preparing ${file}"

		file_path_md5=$(echo "${file_path}" | md5sum | awk '{print $1;}')
		file_content_md5=$(md5sum ${file_path} | awk '{print $1;}')
		file_info_enc=$(echo "${file}" | openssl enc -aes-256-cbc -salt -pbkdf2 -a -kfile password)

		echo " - file path: ${file_path}"
		echo " - file path (md5): ${file_path_md5}"
		echo " - file content (md5): ${file_content_md5}"

		echo "${file_path_md5}-${file_content_md5}|${file_path}|${line}" >> tmp/files.list
	fi
done

#CHECK BACKUP
echo "== Checking for an existing backup"

EXISTS_BACKUP_DIRECTORY=$(s3cmd ls -c ${S3CMD_CONFIG} s3://${BUCKET_NAME} 2>/dev/null | grep ${HASH_PATH})
EXISTING_FILES=

if [ -z "${EXISTS_BACKUP_DIRECTORY}" ]
then
	echo "- it's the first backup!"
else
	echo "== Listing existing files in the backup"
	s3cmd ls -c ${S3CMD_CONFIG} s3://${BUCKET_NAME}/${HASH_PATH}/ 2>/dev/null > tmp/existing_files.list

	echo "== Deleting older files in the backup"
	
	cat tmp/existing_files.list | while read line
	do
		#file_path=$(echo "${line}" | awk '{print $NF;}')
		file_path=$(echo "${line}" | tr " " "\n" | tail -1)
		#file_name=$(echo "${file_path}" | awk -F "/" '{print $NF;}')
		file_name=$(echo "${file_path}" | tr "/" "\n" | tail -1)
		file_exists_in_local=$(cat tmp/files.list | grep "$file_name")

		if [ -z "${file_exists_in_local}" ]
		then
			s3cmd rm -c ${S3CMD_CONFIG} ${file_path} 2>/dev/null
		fi
	done
fi

echo "== Uploading new files in the backup"

cat tmp/files.list | while read line
do
	file_name=$(echo "${line}" | cut -d"|" -f1)
	file_exists_in_s3=$(cat tmp/existing_files.list | grep "${file_name}")
	if [ -z "${file_exists_in_s3}" ]
	then
		file_path=$(echo "${line}" | cut -d"|" -f2)
		openssl enc -aes-256-cbc -salt -pbkdf2 -a -kfile password -in ${file_path} -out "tmp/${file_name}"
		s3cmd put -c ${S3CMD_CONFIG} --storage-class GLACIER tmp/${file_name} s3://${BUCKET_NAME}/${HASH_PATH}/${file_name} 2>/dev/null
		rm tmp/${file_name}
	fi
done

#encrypt file.list
openssl enc -aes-256-cbc -salt -pbkdf2 -a -kfile password -in tmp/files.list -out tmp/files.list.enc

#upload file.list
s3cmd put -c ${S3CMD_CONFIG} tmp/files.list.enc s3://${BUCKET_NAME}/${HASH_PATH}/files.list.enc 2>/dev/null

echo "Done!"
