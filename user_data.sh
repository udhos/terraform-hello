#!/bin/bash

APP_URL=https://github.com/udhos/gowebhello/releases/download/v0.7/gowebhello_linux_amd64

echo >&2 "env var APP_URL=[$APP_URL]"

if [ -z "$APP_URL" ]; then
	echo >&2 "missing env var APP_URL=[$APP_URL]"
	exit 1
fi

app_dir=/web

[ -d $app_dir ] || mkdir $app_dir
cd $app_dir || echo >&2 "could not cd: app_dir=$app_dir"

[ -f gowebhello ] || curl -L -o gowebhello "$APP_URL"

chmod a+rx gowebhello

#
# web service
#

cat >/lib/systemd/system/web.service <<__EOF__
[Unit]
Description=Gowebhello Service
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=$app_dir
ExecStart=$app_dir/gowebhello
Restart=on-failure
[Install]
WantedBy=multi-user.target
__EOF__

systemctl daemon-reload
systemctl enable web.service --now
#systemctl restart web.service

echo "check service: systemctl status web"
echo "check logs:    journalctl -u web -f"
