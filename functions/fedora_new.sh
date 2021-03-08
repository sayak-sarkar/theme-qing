#!/bin/bash

# archey-osx 1.5.2 (https://github.com/obihann/archey-osx/)

# test to see if bash supports arrays
arraytest[0]='test' || (echo 'Error: Arrays are not supported in this version of
bash.' && exit 2)

# Detect the packager.
#if [ -x /usr/local/bin/brew ]; then
  #detectedpackager=homebrew
#elif command -v port >/dev/null; then
  #detectedpackager=macports
#else
  #detectedpackager=none
#fi

# Get the command line options
opt_nocolor=f
opt_force_color=f
opt_offline=f
for arg in "$@"
do
  case "${arg}" in
    -p|--packager)
      packager=$detectedpackager
      ;;
    -m|--macports)
      packager=macports
      ;;
    -b|--nocolor)
      opt_nocolor=t
      ;;
    -c|--color)
      opt_nocolor=f
      opt_force_color=t
      ;;
    -o|--offline)
        opt_offline=t
      ;;
    -h|--help)
      echo "Archey OS X 1.5.2"
      echo
      echo "Usage: $0 [options]"
      echo
      echo "  -p --packager  Use auto detected package system (default packager: ${detectedpackager})."
      echo "  -m --macports  Force use MacPorts as package system."
      echo "  -b --nocolor   Turn color off."
      echo "  -c --color     Force the color on (overrides --nocolor)."
      echo "  -o --offline Disable the IP address check."
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" 1>&2
      echo "For help, use: $0 --help" 1>&2
      exit 1
      ;;
  esac
done

# System Variables
user=$(whoami)
hostname=$(hostname | sed 's/.local//g')

#if [[ "${opt_offline}" = f ]]; then
    #ipfile="${HOME}/.archey-ip"
    #if [ -a "$ipfile" ] && test `find "$ipfile" -mmin -360`; then
        #while read -r line; do
            #ip="$line"
        #done < "$ipfile"
    #else
        #ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
        #echo $ip > "$ipfile"
    #fi
#fi

system_manufacturer="$(sudo dmidecode -s system-manufacturer)"
system_version="$(sudo dmidecode -s system-version)"
system_product_name="$(sudo dmidecode -s system-product-name)"
distro="$(awk -F "=" '/NAME/ {print $2}' /etc/os-release | head -1) $(awk -F "=" '/VERSION/ {print $2}' /etc/os-release | head -1 | sed 's/"//g')"
kernel=$(uname -sr)
uptime=$(uptime | awk -F'( |,|:)+' '{print $6,$7",",$8,"hours,",$9,"minutes."}')
desktop_environment="$XDG_CURRENT_DESKTOP"
shell="$SHELL"
terminal="$TERM ${TERM_PROGRAM//_/ }"
cpu=$(awk -F ": " '/model name|siblings/ {print $2}' /proc/cpuinfo | head -2 | sed ':a;N;$!ba;s/\n/ x /g')
#battery=$(ioreg -c AppleSmartBattery -r | awk '$1~/Capacity/{c[$1]=$3} END{OFMT="%.2f%%"; max=c["\"MaxCapacity\""]; print (max>0? 100*c["\"CurrentCapacity\""]/max: "?")}')
battery=$(echo $(cat /sys/class/power_supply/BAT0/capacity)%)

# removes (R) and (TM) from the CPU name so it fits in a standard 80 window
# cpu=$(echo "$cpu" | awk '$1=$1' | sed 's/([A-Z]\{1,2\})//g')

ram="$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 ** 2 )) GB"
disk=$(systemctl --user stop xdg-document-portal.service; df | head -5 | tail -1 | awk '{print $5}')


# Set up colors if:
# * stdout is a tty
# * the user hasn't turned it off
# * or if we're forcing color
if [[ ( -t 1  && "${opt_nocolor}" = f) || "${opt_force_color}" = t ]]
then
  RED=$(tput       setaf 1 2>/dev/null)
  GREEN=$(tput     setaf 2 2>/dev/null)
  YELLOW=$(tput    setaf 3 2>/dev/null)
  BLUE=$(tput      setaf 4 2>/dev/null)
  PURPLE=$(tput    setaf 5 2>/dev/null)
  textColor=$(tput setaf 6 2>/dev/null)
  normal=$(tput    sgr0 2>/dev/null)
fi

case "${packager}" in
  homebrew)
    packagehandler=$(brew list -1 | wc -l | awk '{print $1 }')
    ;;
  macports)
    packagehandler=$(port installed | wc -l | awk '{print $1 }')
    ;;
  *)
    packagehandler=0
    ;;
esac

fieldlist[${#fieldlist[@]}]="${textColor}User:${normal} ${user}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}Hostname:${normal} ${hostname}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}Model:${normal} ${system_manufacturer} ${system_version} ${system_product_name}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}Distro:${normal} ${distro}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}Kernel:${normal} ${kernel}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}Uptime:${normal} ${uptime}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}DesktopEnvironment:${normal} ${desktop_environment}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}Shell:${normal} ${shell}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}Terminal:${normal} ${terminal}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}Terminal Size:${normal} $(tput lines) x $(tput cols)"
#if [ ${packagehandler} -ne 0 ]; then
    #fieldlist[${#fieldlist[@]}]="${textColor}Packages:${normal} ${packagehandler}${normal}"
#fi
fieldlist[${#fieldlist[@]}]="${textColor}CPU:${normal} ${cpu}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}Memory:${normal} ${ram}${normal}"
fieldlist[${#fieldlist[@]}]="${textColor}Disk:${normal} ${disk}${normal}"
#if [ ! -z $battery ]; then
#fi
fieldlist[${#fieldlist[@]}]="${textColor}Battery:${normal} ${battery}${normal}"

#if [ "${opt_offline}" = f ]; then
    #fieldlist[${#fieldlist[@]}]="${textColor}IP Address:${normal} ${ip}${normal}"
#fi

fieldlist[${#fieldlist[@]}]="${textColor}Date:${normal} $(date)${normal}"

logofile=${ARCHEY_LOGO_FILE:-"${HOME}/.config/archey-logo"}
if [ -a "$logofile" ]
  then
  source "$logofile"
else
# The ${foo#  } is a cheat so that it lines up here as well
# as when run.
echo -e "
${BLUE#  }                  ,,          ${fieldlist[0]}
${BLUE#  }                shdhbg        ${fieldlist[1]}
${BLUE#  }              omMMMNNMMb      ${fieldlist[2]}
${GREEN#  }             sMMP    YUY      ${fieldlist[3]}
${GREEN#  }             MMM              ${fieldlist[4]}
${GREEN# }             MMM              ${fieldlist[5]}
${YELLOW# }       +++++ MMmhhb           ${fieldlist[6]}
${YELLOW#    }    ++++++++ MMMMMP           ${fieldlist[7]}
${YELLOW#    }  +++'       MMM              ${fieldlist[8]}
${PURPLE#    } +++         MMy              ${fieldlist[9]}
${PURPLE# } +++         MMy              ${fieldlist[10]}
${PURPLE# } ++++       hMM+              ${fieldlist[11]}
${RED#   }   dMNdyyydNMNo               ${fieldlist[12]}
${RED#   }     YNMMMMNP                 ${fieldlist[13]}
${RED#   }       '''                    ${fieldlist[14]}
 ${normal}
"
fi
