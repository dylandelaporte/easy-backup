# Easy backup

S3 storage type backup solution with highly encrypted data. Files are ony readable from your computer using a key. The tool makes it easy to manage multiple backups and update modified files on the s3 storage. To save cost files are saved to glacier and the index file is on the normal storage.

## Backup
`./backup.sh --backup-name BACKUP_NAME --directory-to-backup DIRECTORY_TO_BACKUP --s3cmd-config S3CMD_CONFIG --bucket-name BUCKET_NAME`

## Wipe
`./wipe.sh --backup-name BACKUP_NAME --s3cmd-config S3CMD_CONFIG --bucket-name BUCKET_NAME`

## Upcoming features
- restore backup
- list backups
- init script
