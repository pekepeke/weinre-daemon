#!/bin/bash

opt_uninstall=0
AGENT_PLIST="com.github.pekepeke.weinre.plist"
CMD_OPTION="--boundHost=0.0.0.0 --httpPort=58080"

usage() {
  prg_name=`basename $0`
  cat <<EOM
  Usage: $prg_name [-h]
  -h : Show this message
  -u : Uninstall
EOM
  exit 1
}

weinred_plist() {
  LABEL=$1
  BIN=$2
  cat <<EOM
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>$BIN</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>OnDemand</key>
  <false/>
</dict>
</plist>
EOM
}

install_repository() {
  if [ ! -e ~/.weinred ]; then
    git clone https://github.com/pekepeke/weinre-daemon ~/.weinred
    cd ~/.weinred
    git submodule update --init --recursive
  else
    cd ~/.weinred
    git pull
    git submodule update --recursive
    npm install
  fi
}

install_osx() {
  local LABEL=$(basename $AGENT_PLIST .plist)
  weinred_plist $LABEL "$HOME/.weinred/node_modules/.bin/weinre ${CMD_OPTION}" > "$HOME/Library/LaunchAgents/$AGENT_PLIST"
  launchctl load -Fw "$HOME/Library/LaunchAgents/$AGENT_PLIST"
}

uninstall_osx() {
  launchctl unload "$HOME/Library/LaunchAgents/$AGENT_PLIST"
  rm "$HOME/Library/LaunchAgents/$AGENT_PLIST"
}

exec_uninstall() {
  uninstall_osx
}

exec_install() {
  local shortuname=$(uname -s)
  if [ "${shortuname}" != "Darwin" ]; then
    echo "Sorry, requires Mac OS X to run." >&2
    exit 1
  fi
  install_osx
}

main() {
  if [ $opt_uninstall -eq 1 ]; then
    exec_uninstall
  else
    exec_install
  fi
}

OPTIND_OLD=$OPTIND
OPTIND=1
while getopts "hu" opt; do
  case $opt in
    h)
      usage ;;
    u)
      opt_uninstall=1
      ;;
  esac
done
shift `expr $OPTIND - 1`
OPTIND=$OPTIND_OLD
if [ $OPT_ERROR ]; then
  usage
fi

main "$@"

