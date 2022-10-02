#!/bin/bash

# Constants
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
dir=$(basename "$SCRIPT_DIR")

# Change this if you want to fork the project
enableUpdate="true"
targetRepo="https://github.com/truecharts/truetool.git"

# CD to the folder containing the script to ensure consistent runs
cd "${SCRIPT_DIR}" || echo -e "ERROR: Something went wrong accessing the script directory"

# Includes
# shellcheck source=includes/backup.sh
source includes/backup.sh
# shellcheck source=includes/chores.sh
source includes/chores.sh
# shellcheck source=includes/colors.sh
source includes/colors.sh
# shellcheck source=includes/dns.sh
source includes/dns.sh
# shellcheck source=includes/help.sh
source includes/help.sh
# shellcheck source=includes/mount.sh
source includes/mount.sh
# shellcheck source=includes/no_args.sh
source includes/no_args.sh
# shellcheck source=includes/title.sh
source includes/title.sh
# shellcheck source=includes/update.sh
source includes/update.sh
# shellcheck source=includes/update_self.sh
source includes/update_self.sh

#If no argument is passed, set flag to show menu
if [[ -z "$*" || "-" == "$*" || "--" == "$*"  ]]; then
  no_args="true"
else

  # Parse script options
  while getopts ":si:b:t:uUpSv-:" opt
  do
      case $opt in
        -)
          case "${OPTARG}" in
            help)
                  help="true"
                  ;;
              dns)
                  dns="true"
                  ;;
            mount)
                  mountPVC="true"
                  ;;
            restore)
                  restore="true"
                  ;;
            delete-backup)
                  deleteBackup="true"
                  ;;
            list-backups)
                  listBackups="true"
                  ;;
            helm-enable)
                  helmEnable="true"
                  ;;
            apt-enable)
                  aptEnable="true"
                  ;;
            kubeapi-enable)
                  kubeapiEnable="true"
                  ;;
            no-auto-update)
                  enableUpdate="false"
                  ;;
            no-color)
                  noColor
                  ;;
            *)
                  echo -e "Invalid Option \"--$OPTARG\"\n" && help
                  exit
                  ;;
          esac
          ;;
        \?)
          echo -e "Invalid Option \"-$OPTARG\"\n" && help
          exit
          ;;
        :)
          echo -e "Option: \"-$OPTARG\" requires an argument\n" && help
          exit
          ;;
        b)
          re='^[0-9]+$'
          number_of_backups=$OPTARG
          ! [[ $OPTARG =~ $re  ]] && echo -e "Error: -b needs to be assigned an interger\n\"""$number_of_backups""\" is not an interger" >&2 && exit
          [[ "$number_of_backups" -le 0 ]] && echo "Error: Number of backups is required to be at least 1" && exit
          ;;
        i)
          ignore+=("$OPTARG")
          ;;
        t)
          re='^[0-9]+$'
          timeout=$OPTARG
          ! [[ $timeout =~ $re ]] && echo -e "Error: -t needs to be assigned an interger\n\"""$timeout""\" is not an interger" >&2 && exit
          ;;
        s)
          sync="true"
          ;;
        U)
          update_all_apps="true"
          ;;
        u)
          update_apps="true"
          ;;
        p)
          prune="true"
          ;;
        v)
          verbose="true"
          ;;
        *)
          echo -e "Invalid Option \"--$OPTARG\"\n" && help
          exit
          ;;
      esac
  done
fi

title

[[ "$enableUpdate" == "true" ]] && updater "$@"

# Show menu if menu flag is set
if [[ "$no_args" == "true"  ]]; then
  no_args
fi

## Exit if incompatable functions are called
[[ "$update_all_apps" == "true" && "$update_apps" == "true" ]] && echo -e "-U and -u cannot BOTH be called" && exit

## Exit if unsafe combinations are used
# Restore and update right after eachother, might cause super weird issues tha are hard to bugtrace
[[ ( "$update_all_apps" == "true" || "$update_apps" == "true" ) && ( "$restore" == "true" ) ]] && echo -e "Update and Restore cannot both be done in the same run..." && exit

# Backup Deletion is generally considered to be a "once in a while" thing and not great to sync with automated updates for that reason
[[ ( "$update_all_apps" == "true" || "$update_apps" == "true" ) && ( "$deleteBackup" == "true" ) ]] && echo -e "Update Backup-Deletion cannot both be done in the same run..." && exit

# Backup Deletion is generally considered to be a "once in a while" thing and not great to sync with automated updates for that reason
[[ ( "$update_all_apps" == "true" || "$update_apps" == "true" ) && ( "$deleteBackup" == "true" ) ]] && echo -e "Update and Backup-Deletion cannot both be done in the same run..." && exit

# Backup listing is a printout, which would either clutter the output or be already outdated when combined with backup
[[ ( "$update_all_apps" == "true" || "$update_apps" == "true" ) && ( "$listBackups" == "true" ) ]] && echo -e "Update and Listing Backups cannot both be done in the same run..." && exit

# Backup backup would be done after a backup is restored, which would lead to a backup that is... the same as the one restored...
[[ ( "$restore" == "true" && "$number_of_backups" -ge 1 )]] && echo -e "Restoring a backup and making a backup cannot both be done in the same run..." && exit

# While technically possible, this is asking for user error... where a user by habit mistakes one prompt, for the other.
[[ ( "$restore" == "true" && "$deleteBackup" == "true" )]] && echo -e "restoring a backup and deleting a backup cannot both be done in the same run..." && exit


# Continue to call functions in specific order
[[ "$help" == "true" ]] && help
[[ "$helmEnable" == "true" ]] && helmEnable
[[ "$aptEnable" == "true" ]] && aptEnable
[[ "$kubeapiEnable" == "true" ]] && kubeapiEnable
[[ "$aptEnable" == "true" || "$helmEnable" == "true" || "$kubeapiEnable" == "true" ]] && exit
[[ "$listBackups" == "true" ]] && listBackups && exit
[[ "$deleteBackup" == "true" ]] && deleteBackup && exit
[[ "$dns" == "true" ]] && dns && exit
[[ "$restore" == "true" ]] && restore && exit
[[ "$mountPVC" == "true" ]] && mountPVC && exit
[[ "$number_of_backups" -ge 1 ]] && backup
[[ "$sync" == "true" ]] && sync
[[ "$update_all_apps" == "true" || "$update_apps" == "true" ]] && update_apps
[[ "$prune" == "true" ]] && prune
