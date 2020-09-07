# Easy backup

S3 storage type backup solution with highly encrypted data. Files are ony readable from your computer using a key. The tool makes it easy to manage multiple backups and update modified files on the s3 storage. To save cost files are saved to glacier and the index file is on the normal storage.

## Backup
`./backup.sh --directory-to-backup DRECTORY_TO_BACKUP --s3cmd-config S3CMD_CONFIG`

## Wipe
`./wipe.sh --directory-to-backup DRECTORY_TO_BACKUP --s3cmd-config S3CMD_CONFIG`