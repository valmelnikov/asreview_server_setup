#!/bin/bash
# Adopted from https://wiki.archlinux.org/title/rsync

ASREVIEW_DIR=/home/vmelnik/.asreview
BACKUP_DIR=/home/vmelnik/backup/
TIME_LABEL=$(date +%F_%H-%M-%S)

cd $ASREVIEW_DIR
echo $TIME_LABEL

for PROJECT_PATH in $(ls -d */)
do
	FULL_PROJECT_PATH="${ASREVIEW_DIR}/${PROJECT_PATH}"
	FULL_PROJECT_BACKUP_PATH="${BACKUP_DIR}full/${PROJECT_PATH}"
	INCR_PROJECT_BACKUP_PATH="${BACKUP_DIR}incr/${PROJECT_PATH}"

	if test -d "$INCR_PROJECT_BACKUP_PATH"; then
		echo "Incremental backup folder for ${PROJECT_PATH} exists"
	else
		mkdir $INCR_PROJECT_BACKUP_PATH
	fi	

	OPT="-aPh"
	LAST="${INCR_PROJECT_BACKUP_PATH}last"
	echo $LAST
	LINK="--link-dest=${LAST}" 
	SRC=$FULL_PROJECT_PATH
	SNAP=$INCR_PROJECT_BACKUP_PATH

	# Run rsync to create snapshot
	rsync $OPT $LINK $SRC ${SNAP}$TIME_LABEL

	# Remove symlink to previous snapshot
	rm -f $LAST

	# Create new symlink to latest snapshot for the next backup to hardlink
	ln -s ${SNAP}$TIME_LABEL $LAST
	
	# echo $FULL_PROJECT_BACKUP_PATH
	# if test -d "$FULL_PROJECT_BACKUP_PATH"; then
	#	echo "$FULL_PROJECT_BACKUP_PATH exists"
	# else
	#	echo "Full backup does not exist."
	#	rsync -a --backup $FULL_PROJECT_PATH $FULL_PROJECT_BACKUP_PATH
	#	mkdir $INCR_PROJECT_BACKUP_PATH
	# fi
	# rsync -a --backup --inplace --backup-dir="${INCR_PROJECT_BACKUP_PATH}/${TIME_LABEL}" $FULL_PROJECT_PATH $FULL_PROJECT_BACKUP_PATH 
done
