#!/bin/bash

# Perform any script actions which need to happen after switching to the latest
# tagged release

main(){
  # service files may have changed so reload them
  systemctl --user daemon-reload

  # if it's an old install without auto deps we should do a complete recompile
  if [ ! -f vbit2.d ]; then
    # hope that presence of vbit2.d means all dep files are present
    make clean
  fi

  # offer to upgrade old installs to new scripts (runs getvbit2)
  migrate

  # recompile vbit2
  make

  # restart vbit if service is active
  if [[ `systemctl --user is-active vbit2.service` == "active" ]]; then
    systemctl --user restart vbit2.service
  fi
}

migrate(){
  FOUND=()
  if [ -f $HOME/vb2 ]; then FOUND+=("$HOME/vb2"); fi
  if [ -f $HOME/vbit2.sh ]; then FOUND+=("$HOME/vbit2.sh"); fi
  if [ -f $HOME/updatePages.sh ]; then FOUND+=("$HOME/updatePages.sh"); fi
  if [ -d $HOME/raspi-teletext-master ]; then FOUND+=("$HOME/raspi-teletext-master"); fi
  if [ -d $HOME/Pages ]; then FOUND+=("$HOME/Pages"); fi
  if [ -f /etc/systemd/system/vbit2.service ]; then FOUND+=("/etc/systemd/system/vbit2.service"); fi
  if [ ! ${#FOUND[@]} -eq 0 ]; then
    printf 'The following files were found which relate to an old version of vbit2:' | fold -s -w `tput cols`
    printf '\n%s' "${FOUND[@]}" | fold -s -w `tput cols`
    printf '\n\nIt is recommended to upgrade to the new system which includes the interactive vbit-config utility.\nDo you wish to attempt to reinstall vbit2 automatically?\n\033[1mCaution: this will remove the files and directories listed above losing any local changes you have made.\033[0m\n' | fold -s -w `tput cols`
    read -p "(y)es (n)o" -n 1 -s
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      printf "leaving start scripts unchanged.\n"
    else
      # Here Be Dragons!
      # remove any updatePages.sh cron job
      sudo crontab -l | grep -v 'updatePages.sh' | sudo crontab -
      crontab -l | grep -v 'updatePages.sh' | crontab -
      # delete the old files and directories
      sudo systemctl disable vbit2 --now
      sudo rm -rf ${FOUND[@]}
      # run the new installer
      ./getvbit2

      if [ -d $HOME/teletext ]; then
        printf 'The directory %s is no longer required.\n' "$HOME/teletext"
      fi

    fi
  fi
}

main; exit
