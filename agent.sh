#!/bin/bash

# Variables
CONFIGDIR="/etc/cpsagent"
SCRIPTSDIR="$CONFIGDIR/scripts.d"
LOGDIR="/var/log/cps"
LOGPATH="$LOGDIR/agent.log"
CHKSTORE="$CONFIGDIR/.chksumstore"

# Create log directory if not exists
if [ ! -d "$LOGDIR" ]; then
    mkdir "$LOGDIR"
    touch "$LOGPATH"
fi

# Check for configuration directory existance
if [ ! -d  "$CONFIGDIR" ]; then
    echo "Creating Directory: $CONFIGDIR" | tee -a "$LOGPATH"
    mkdir "$CONFIGDIR"
    chown "$CPSUSER":"$CPSUSER" "$SCRIPTSDIR" 
fi

# Check for scripts directory existance
if [ ! -d  "$SCRIPTSDIR" ]; then
    echo "Creating Directory: $SCRIPTSDIR" | tee -a "$LOGPATH"
    mkdir "$SCRIPTSDIR"
    chown -R "$CPSUSER":"$CPSUSER" "$SCRIPTSDIR" 
fi

# Check .chkstore file existence
if [ ! -f  "$CHKSTORE" ]; then
    echo "Creating Checksum Store File ..." | tee -a "$LOGPATH"
    touch "$CHKSTORE"
    chown "$CPSUSER":"$CPSUSER" "$CHKSTORE"
    chmod 0400 "$CHKSTORE"
fi

echo -e "\n##################################################" | tee -a $LOGPATH
echo "$(date +'%m/%d/%Y %H:%M') Service Started." | tee -a "$LOGPATH"
echo -e "##################################################\n" | tee -a $LOGPATH

# Set shell option for iterating over files in for-each block
shopt -s nullglob

while true 
do

# Execute all shell scripts
for FILE in "$SCRIPTSDIR"/*.sh
do

    CHKSUM=$(grep "$FILE" "$CHKSTORE")

    if [[ (-z $CHKSUM ) || ($CHKSUM != $(md5sum "$FILE") ) ]]; then
        echo -e "\n$(date +'%m/%d/%Y %H:%M') Running $FILE..." | tee -a "$LOGPATH"
        bash "$FILE" | tee -a $LOGPATH
        sed -i '\:'"$FILE"':d' $CHKSTORE
        md5sum "$FILE" >> $CHKSTORE
    fi
    
done

sleep 15s

done
