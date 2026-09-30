#!/usr/bin/env bash

set -Eeuo pipefail

# Root user validation:
if [ "$(id -u)" -ne 0 ]; then
  echo "Script must be executed as root." "$(id -u)"
  exit 1
fi

UPDATE_LOG_DIR="/var/log/sys_update"

if [ ! -d "$UPDATE_LOG_DIR" ]; then
  mkdir $UPDATE_LOG_DIR
fi

UPDATE_LOG="$UPDATE_LOG_DIR/update_log.log"

check_for_network_conn() {
  echo -e "\n"
  echo -e "checking for network connection... \n"

  if ping -c 3 google.com &>/dev/null; then
    echo -e "Network status: OK \n"
    return 0
  else
    return 1
  fi
}

find_package_manager() {
  MANAGERS=("apt" "dnf" "pacman" "zypper")

}

update_sys() {
  local retries=3
  local counter=0

  echo -e "Starting the system update... \n"

  until apt -y update && apt -y upgrade; do
    if [ $counter -ge $retries ]; then
      echo "Could not update the system after $retries. Aborting. $(date)" | tee -a $UPDATE_LOG
      echo "Fail to updating... Tryng again in 5 secs." | tee -a $UPDATE_LOG
      echo -e "\n"
      return 1
    fi

    sleep 5
    counter=$((counter + 1))
  done
}
clean_cache_and_logs() {
  apt -y autoclean
  find /var/log/ -type f -name "*.log" -exec truncate -s 0 {} \;
  find /var/log -type f -name "*.log" -mtime +30 -exec rm -f {} \; #Logs 30+ days old
}
if ! check_for_network_conn; then
  echo "Something's wrong. Check your network connection. $(date)" | tee -a $UPDATE_LOG
  echo -e "\n"
  exit 1
fi

if ! update_sys; then
  echo "Not able to update the system. Aborting." | tee -a $UPDATE_LOG
  exit 1
fi

# Calls the function
clean_cache_and_logs

echo -e "\n"
echo "System updating, cache and logs cleaning: successfully! $(date)" | tee -a $UPDATE_LOG
