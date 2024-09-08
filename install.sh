#!/bin/bash

#Copy executable script
mkdir -p /opt/SAQLottery
cp SAQLottery.sh /opt/SAQLottery/SAQLottery.sh

#Create SAQLottery service
cat <<EOF >/etc/systemd/system/saqlottery.timer
[Unit]
Description=SAQLottery timer
Requires=saqlottery.service

[Timer]
Unit=saqlottery.service
OnCalendar=00/2:00

[Install]
WantedBy=timers.target
EOF

cat <<EOF >/etc/systemd/system/saqlottery.service
[Unit]
Description=SAQLottery service
After=network.target
Wants=saqlottery.timer

[Service]
Type=oneshot
#Environment="discord_webhook_url=https://discord.com/api/webhooks/<REPLACE BY YOUR OWN URL AND UNCOMMENT>"
ExecStart=bash /opt/SAQLottery/SAQLottery.sh
StandardOutput=truncate:/var/log/saqlottery.log
StandardError=truncate:/var/log/saqlottery.log

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now saqlottery.timer