From a post by nullstring. Copying here for safekeeping.

<pre>
Nullstring's Automatic #DVD #Ripping Riggingill pin this for you bbsPart One - Imaging

This rigging sets up such that when a DVD is inserted into any connected optical drive, a udev rule triggers a systemd service which images the DVD to an ISO in the specified users home directory. this uses dvdbackup and genisoimage to create an unencrypted 1:1 DVD ISO including original menus and such.UDEV

Create a UDEV trigger for when a media DVD is detected when the tray is closed and call a systemd service providing the detected devices name./etc/udev/rules.d/85-auto-rip.rulesACTION=="change", SUBSYSTEM=="block", KERNEL=="sr[0-9]*", ENV{DISK_MEDIA_CHANGE}=="1", ENV{ID_CDROM_MEDIA_DVD}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}="auto-rip@%k.service"
systemd (im sorry)

Create a systemd service to call a script as a specific user and pass it the device name as a path gotten from the udev rule./etc/systemd/system/auto-rip@.service[Unit]
Description=Rip DVD from %i
Requires=dev-%i.device
After=dev-%i.device
BindsTo=dev-%i.device
ConditionPathExists=/dev/%i
ConditionKernelCommandLine=!rd.break
StartLimitIntervalSec=0
StartLimitBurst=0

[Service]
Type=simple
User=user
Group=user
# you will need to update this to a real username, preferably the one your are using!
Environment="HOME=/home/user"
Environment="USER=user"
Environment="LOGNAME=user"
Environment="SHELL=/bin/bash"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Use absolute path to script
ExecStart=/usr/local/bin/autorip_systemd.sh /dev/%i

# Timeouts (adjust as needed)
TimeoutStartSec=0
TimeoutStopSec=30

# Process management
Restart=no
KillMode=process
SendSIGKILL=no

# Resource limits (optional)
#MemoryMax=2G
#CPUQuota=80%

# Nice level (prioritize ripping)
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=auto-rip-%i

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
# here too you need a real username
ReadWritePaths=/home/user/DVD_Backups
ReadOnlyPaths=/dev/%i /usr/bin /usr/local/bin

[Install]
WantedBy=multi-user.target
iso ripping script

Create a script to use makemkvcon and ddrescue to reliably ISO off DVDs and name them based on the contained disk title. youd need to edit this to use a real username instead of user and to make sure the paths are to your liking./usr/local/bin/autorip_systemd.sh#!/bin/sh

set -e

OUTPUT_DIR="/home/user/DVD_Backups"
LOG="/home/user/optical_insert.log"
MAX_RETRIES=5
DEVICE="$1"
[ -z "$DEVICE" ] && exit 99
echo "=== Checking Disk Type on $DEVICE ===" >> $LOG
eval $(udevadm info --query=property --export "$DEVICE")
sleep 3
echo "Date: $(date)">> "$LOG"
echo "DEVNAME=$DEVNAME">> "$LOG"
echo "DEVPATH=$DEVPATH">> "$LOG"
echo "ID_CDROM_MEDIA=$ID_CDROM_MEDIA">> "$LOG"
echo "ID_CDROM_MEDIA_DVD=$ID_CDROM_MEDIA_DVD">> "$LOG"
echo "ID_FS_TYPE=$ID_FS_TYPE">> "$LOG"
[ "$ID_CDROM_MEDIA_DVD" -ne "1" ] && exit 98
echo "=== DVD Check OKAY, checking title ===" >> $LOG
DISC_TITLE1=$(makemkvcon -r info disc:0 2>&1)
echo "[DEBUG] $DISC_TITLE1" >> $LOG
DISC_TITLE=$(echo "$DISC_TITLE1" | grep -oP 'DRV:0,\d+,\d+,\d+,"[^"]+",".*",".+"')
sleep 3
[ -z "$DISC_TITLE" ] && DISC_TITLE="\"Unknown_DVD\""
CLEAN_TITLE=$(echo "$DISC_TITLE" | cut -d, -f6 | awk '{print substr($0, 2, length($0)-2)}' | tr -d '\n')
echo "Title: $CLEAN_TITLE" >> $LOG
mkdir -p "$OUTPUT_DIR/$CLEAN_TITLE"
echo "Telling HA we are ripping '$CLEAN_TITLE' now" >> $LOG
/usr/local/bin/hastatus.sh "ripping '$CLEAN_TITLE'"
dvdbackup -i "$DEVICE" -o "$OUTPUT_DIR/$CLEAN_TITLE/" -M
return_code=$?
HAMESSAGE=""
if [ $return_code -eq 0 ]; then
    $HAMESSAGE = "'$CLEAN_TITLE' backup completed. Generating ISO..."
elif [ $return_code -eq 1 ]; then
    $HAMESSAGE = "Usage error for '$CLEAN_TITLE'"
elif [ $return_code -eq 2 ]; then
    $HAMESSAGE = "Title name error for '$CLEAN_TITLE', re-running with generic name"
    dvdbackup -i "$DEVICE" -o "$OUTPUT_DIR/$CLEAN_TITLE/" -M -n "$CLEAN_TITLE"
    $return_code=$?
    if [ $return_code -ne "0"]; then
        echo "failed to copy even with forced title for '$CLEAN__TITLE'" >> $LOG
        /usr/local/bin/hastatus.sh "failed to copy even with forced title for '$CLEAN__TITLE'"
        exit 65
    fi
elif [ $return_code -eq -1 ]; then
    $HAMESSAGE = "dvdbackup command failed for '$CLEAN_TITLE'"
else
    $HAMESSAGE = "Unknown exit status for '$CLEAN_TITLE': $return_code"
fi
/usr/local/bin/hastatus.sh "$HAMESSAGE"
echo "$HAMESSAGE"
DVDBACKUPFILENAME=$(ls $OUTPUT_DIR/$CLEAN_TITLE/ | grep -v *.iso | tr -d '\n')
genisoimage -dvd-video -udf -o "$OUTPUT_DIR/$CLEAN_TITLE/$DVDBACKUPFILENAME.iso" "$OUTPUT_DIR/$CLEAN_TITLE/$DVDBACKUPFILENAME"
$return_code = $?
if [ $return_code -ne "0"]; then
    echo "iso generation failed! boooo" >> $LOG
    /usr/local/bin/hastatus.sh "ISO generation failed for '$CLEAN_TITLE'"
    exit 66
fi
/usr/bin/eject "$DEVICE"
$HAMESSAGE = "'$CLEAN_TITLE' backup complete, ISO size: $(ls $OUTPUT_DIR/$CLEANTITLE/*.iso | awk '{ print $5 }')"
echo "$HAMESSAGE" >> $LOG
/usr/local/bin/hastatus.sh "$HAMESSAGE"
Setup

do this to keep usb optical drives from suspending in the fucking middle of being read and making shit like ddrescue and dvdbackup not fucking work.# keep usb optical drives from sleeping and ruining everything
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[a-z ]*/& usbcore.autosuspend=-1/' /etc/default/grub
sudo update-grub2
reboot


Finally, copy all these somewhere, and then execute this without reading it at all.# install prereqs
sudo add-apt-repository ppa:heyarje/makemkv-beta -y
sudo apt update
sudo apt install gddrescue coreutils eject at makemkv-oss makemkv-bin libdvd-pkg dvdbackup genisoimage -y
sudo dpkg-reconfigure libdvd-pkg
# set up udev trigger and systemd service
sudo chmod 777 /dev/sr* # make all optical drives accessible
sudo usermod -aG cdrom $USER # add yourself to the cdrom group
sudo cp autorip_systemd.sh /usr/local/bin/autorip_systemd.sh
sudo chmod +x /usr/local/bin/autorip_systemd.sh
sudo cp auto-rip@.service /etc/systemd/system/auto-rip@.service
sudo chmod +x /etc/systemd/system/auto-rip@.service
sudo cp 85-auro-rip.rules /etc/udev/rules.d/85-auto-rip.rules
sudo chmod +x /etc/udev/rules.d/85-auto-rip.rules
# apply udev and systemd changes
sudo udevadm control --reload-rules
sudo systemctl daemon-reload
# now insert a disk and watch
sudo systemctl list-units 'auto-rip@*.service' ; sudo journalctl -u 'auto-rip@*' -f

</pre>

https://infosec.exchange/@0x00string/115789509938830722