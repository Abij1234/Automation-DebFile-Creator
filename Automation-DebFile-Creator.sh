#!/usr/bin/env bash

#---------Coder Details-----------
# Coded by : Abijith@NNC
# Teached by : Suman@BHUTUU
#---------------------------------

#--------- Colour used -----------
S0="\033[1;30m" B0="\033[1;40m"
S1="\033[1;31m" B1="\033[1;41m"
S2="\033[1;32m" B2="\033[1;42m"
S3="\033[1;33m" B3="\033[1;43m"
S4="\033[1;34m" B4="\033[1;44m"
S5="\033[1;35m" B5="\033[1;45m"
S6="\033[1;36m" B6="\033[1;46m"
S7="\033[1;37m" B7="\033[1;47m"
R0="\033[00m"   R1="\033[1;00m"
# --------------------------------

#----------arguments-------------

while getopts ":o:c:b:d:" args; do
  case ${args} in
    o) OUTPUT=$OPTARG;;
    c) CODENAME=$OPTARG;;
    b) BRANCH=$OPTARG;;
    d) DISTRO=$OPTARG;;
  esac
done

if [[ -z $OUTPUT || -z $CODENAME || -z $BRANCH || -z $DISTRO ]]; then
  echo
  echo -e "
        -------------------------------------------------------------------------------
                                        HELP MENU
        -------------------------------------------------------------------------------

        bash Automation-DebFile-Creator.sh -o <output_file> -c <codename> -b <branch> -d <distro>

        EXAMPLE :-

        bash Automation-DebFile-Creator.sh -o coderNNC.repo -c codernnc -b main -d termux

        -------------------------------------------------------------------------------

  " | pv -qL 200 | lolcat
  exit 1
else
  echo
  printf "${S2}WELCOME.........! ${R0}\n"
fi

function check_alldebfiles() {
  if [[ ! -d alldebfiles ]]; then
    echo
    printf "${S1}alldebfiles folder not founded! so creating..... ${R0}\n"
    mkdir alldebfiles
  else
    echo
    printf "${S2}alldebfiles founded successfully..... ${R0}\n"
  fi
}
check_alldebfiles

function perm() {
  chmod 0755 $1/DEBIAN
  if [[ -f ${1}/DEBIAN/postinst ]]; then
    chmod 0555 ${1}/DEBIAN/postinst
  fi
  if [[ -f ${1}/DEBIAN/preinst ]]; then
    chmod 0555 ${1}/DEBIAN/preinst
  fi
}

function AARCH64() {
  perm $1
  dpkg-deb -b $1
  mv ${1}.deb ${1}.aarch64.deb
  mv -v ${1}.aarch64.deb alldebfiles
}

function ARM() {
  perm $1
  dpkg-deb -b $1
  mv ${1}.deb ${1}.arm.deb
  mv -v ${1}.arm.deb alldebfiles
} 

function X86_64() {
  perm $1
  dpkg-deb -b $1
  mv ${1}.deb ${1}.x86_64.deb
  mv -v ${1}.x86_64.deb alldebfiles
}

function I686() {
  perm $1
  dpkg-deb -b $1
  mv ${1}.deb ${1}.i686.deb
  mv -v ${1}.i686.deb alldebfiles
}

function ALL() {
  perm $1
  dpkg-deb -b $1
  mv ${1}.deb ${1}.all.deb
  mv -v ${1}.all.deb alldebfiles
  sed -i 's|Architecture: all|Architecture: aarch64|g' ${1}/DEBIAN/control
  AARCH64 $1
  sed -i 's|Architecture: aarch64|Architecture: arm|g' ${1}/DEBIAN/control
  ARM $1
  sed -i 's|Architecture: arm|Architecture: x86_64|g' ${1}/DEBIAN/control
  X86_64 $1
  sed -i 's|Architecture: x86_64|Architecture: i686|g' ${1}/DEBIAN/control
  I686 $1
  sed -i 's|Architecture: i686|Architecture: all|g' ${1}/DEBIAN/control

}

function main() {
  dirs=($(ls))
  for i in ${dirs[@]}; do
    check=$(tree $i | grep "DEBIAN")
    if [[ ! -z ${check} ]]; then
      archi=$(cat $i/DEBIAN/control | grep "Architecture" | sed -e 's|Architecture: ||g')
      if [[ ${archi} == 'all' ]]; then
        ALL $i
      elif [[ ${archi} == 'aarch64' ]]; then
        AARCH64 $i
      elif [[ ${archi} == 'arm' ]]; then
        ARM $i
      elif [[ ${archi} == 'x86_64' ]]; then
        X86_64 $i
      elif [[ ${archi} == 'i686' ]]; then
        I686 $i
      else
        echo
        printf "${S1}Architecture not supported ${R0}\n"
        exit 1
      fi
      if [[ -f deb-apt-repo.py ]]; then
        python3 deb-apt-repo.py alldebfiles ${OUTPUT} ${CODENAME} ${BRANCH}
        sed -i "s|termux|${DISTRO}|g" ${OUTPUT}/dists/${CODENAME}/Release
        cd ${OUTPUT}/dists/${CODENAME}
        gpg --clear-sign Release
        mv Release.asc InRelease
        sha256sum Release > Release.hash
      fi
    fi
  done
}
main



