#!/bin/bash

# Variables
CONFIGDIR="/etc/cps"
SCRIPTSDIR="$CONFIGDIR/scripts.d"
LOGDIR="/var/log/cps"
LOGPATH="$LOGDIR/server.log"
CHKSTORE="$CONFIGDIR/.chksumstore"
TARGETS="$CONFIGDIR/targets"
CPSUSER="cpsuser"

# Create log directory if not exists
if [ ! -d "$LOGDIR" ]; then
    mkdir "$LOGDIR"
    touch "$LOGPATH"
fi

# Check for configuration directory existance
if [ ! -d  "$CONFIGDIR" ]; then
    echo "$(date +'%m/%d/%Y %H:%M') Creating Directory: $CONFIGDIR" | tee -a "$LOGPATH"
    mkdir "$CONFIGDIR"
    chown "$CPSUSER":"$CPSUSER" "$CONFIGDIR"  
fi

# Check for scripts directory existance
if [ ! -d  "$SCRIPTSDIR" ]; then
    echo "$(date +'%m/%d/%Y %H:%M') Creating Directory: $SCRIPTSDIR" | tee -a "$LOGPATH"
    mkdir "$SCRIPTSDIR"
    chown -R "$CPSUSER":"$CPSUSER" "$SCRIPTSDIR"  
fi

# Check .chkstore file existence
if [ ! -f  "$CHKSTORE" ]; then
    echo "$(date +'%m/%d/%Y %H:%M') Creating Checksum Store File ..." | tee -a "$LOGPATH"
    touch "$CHKSTORE"
    chown "$CPSUSER":"$CPSUSER" "$CHKSTORE"
    chmod 0400 "$CHKSTORE"
fi

# Check .chkstore file existence
if [ ! -f  "$TARGETS" ]; then
    echo "$(date +'%m/%d/%Y %H:%M') Creating Targets File ..." | tee -a "$LOGPATH"
    touch "$TARGETS"
    chown "$CPSUSER":"$CPSUSER" "$TARGETS"
    chmod 0600 "$TARGETS"
fi

echo -e "\n##################################################" | tee -a $LOGPATH
echo "$(date +'%m/%d/%Y %H:%M') Service Started." | tee -a "$LOGPATH"
echo -e "##################################################\n" | tee -a $LOGPATH

# Set shell option for iterating over files in for-each block
shopt -s nullglob

declare -a QUEUE

while true 
do

    QUEUE=()

    # Execute all shell scripts
    for FILE in "$SCRIPTSDIR"/*.sh
    do
        # Search for file checksum
        CHKSUM=$(grep "$FILE" "$CHKSTORE")

        # if checksum does not exist or file is changed
        if [[ (-z $CHKSUM ) || ($CHKSUM != $(md5sum "$FILE") ) ]]; then
            sed -i '\:'"$FILE"':d' $CHKSTORE    # remove old checksum
            md5sum "$FILE" >> $CHKSTORE         # add new checksum
            QUEUE+=("$FILE")                    # add filename to Queue
        fi
    done

    # transfer all files in Queue
    while read -r SERVER
    do
        for Q in ${QUEUE[*]}
        do
            rsync -ahvzt --progress --log-file="$LOGPATH" -e "ssh -o StrictHostKeyChecking=no" "$Q" "$CPSUSER"@"$SERVER":/etc/cpsagent/scripts.d/ 
        done
    done <$TARGETS

    sleep 15s

done
