#!/usr/bin/env bash

###############################################################
## PACKAGE VERSIONS - CHANGE AS REQUIRED
###############################################################
VERSION_PHP="7.4";
VERSION_GO="1.15.6";
VERSION_HELM="3";
VERSION_SOPS="3.1.1";
VERSION_WERF="1.1.21+fix22";
VERSION_NODE="14";
VERSION_POPCORNTIME="0.4.4";
VERSION_PHPSTORM="2020.3";
VERSION_DOCKERCOMPOSE="1.24.1";

# Disallow running with sudo or su
##########################################################
if [[ "$EUID" -eq 0 ]]
  then printf "\033[1;101mNein, Nein, Nein!! Please do not run this script as root (no su or sudo)! \033[0m \n";
  exit;
fi

# Disallow unsupported versions
##########################################################
sudo apt install -y lsb-release;
versionDeb="$(lsb_release -c -s)";
if [[ ${versionDeb} != "stretch" ]] && [[ ${versionDeb} != "buster" ]]
  then printf "\033[1;101mUnfortunatly your OS Version (%s) is not supported. \033[0m \n" "${versionDeb}";
  exit;
fi

###############################################################
## HELPERS
###############################################################
title() {
    printf "\033[1;42m";
    printf '%*s\n'  "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' ';
    printf '%-*s\n' "${COLUMNS:-$(tput cols)}" "  # $1" | tr ' ' ' ';
    printf '%*s'  "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' ';
    printf "\033[0m";
    printf "\n\n";
}

breakLine() {
    printf "\n";
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -;
    printf "\n\n";
    sleep .5;
}

notify() {
    printf "\n";
    printf "\033[1;46m %s \033[0m" "$1";
    printf "\n";
}

curlToFile() {
    notify "Downloading: $1 ----> $2";
    sudo curl -fSL "$1" -o "$2";
}

###############################################################
## REGISTERED VARIABLES
###############################################################
IS_INSTALLED_GO=0;
IS_INSTALLED_ZSH=0;
IS_INSTALLED_PHP=0;
IS_INSTALLED_NODE=0;
IS_INSTALLED_PYTHON=0;
IS_INSTALLED_SUBLIME=0;
IS_INSTALLED_MYSQLSERVER=0;
REPO_URL="https://raw.githubusercontent.com/andrewbrg/deb-dev-machine/master/";

###############################################################
## REPOSITORIES
###############################################################

# PHP
##########################################################
repoPhp() {
    if [[ ! -f /etc/apt/sources.list.d/php.list ]]; then
        notify "Adding PHP sury repository";
        curl -fsSL "https://packages.sury.org/php/apt.gpg" | sudo apt-key add -;
        echo "deb https://packages.sury.org/php/ ${versionDeb} main" | sudo tee /etc/apt/sources.list.d/php.list;
    fi
}

# Yarn
##########################################################
repoYarn() {
    if [[ ! -f /etc/apt/sources.list.d/yarn.list ]]; then
        notify "Adding Yarn repository";
        curl -fsSL "https://dl.yarnpkg.com/debian/pubkey.gpg" | sudo apt-key add -;
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list;
    fi
}

# Docker CE
##########################################################
repoDocker() {
    if [[ ! -f /var/lib/dpkg/info/docker-ce.list ]]; then
        notify "Adding Docker repository";
        curl -fsSL "https://download.docker.com/linux/debian/gpg" | sudo apt-key add -;
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable";
    fi
}

# Kubernetes
##########################################################
repoKubernetes() {
    if [[ ! -f /etc/apt/sources.list.d/kubernetes.list ]]; then
        notify "Adding Kubernetes repository";
        curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | sudo apt-key add -;
        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list;
    fi
}

# Wine
##########################################################
repoWine() {
    if [[ ! -f /var/lib/dpkg/info/wine-stable.list ]]; then
        notify "Adding Wine repository";
        sudo dpkg --add-architecture i386;
        curl -fsSL "https://dl.winehq.org/wine-builds/winehq.key" | sudo apt-key add -;
        curl -fsSL "https://dl.winehq.org/wine-builds/Release.key" | sudo apt-key add -;
        sudo apt-add-repository "https://dl.winehq.org/wine-builds/debian/";
    fi
}

# Atom
##########################################################
repoAtom() {
    if [[ ! -f /etc/apt/sources.list.d/atom.list ]]; then
        notify "Adding Atom IDE repository";
        curl -fsSL "https://packagecloud.io/AtomEditor/atom/gpgkey" | sudo apt-key add -;
        echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" | sudo tee /etc/apt/sources.list.d/atom.list;
    fi
}

# VS Code
##########################################################
repoVsCode() {
    if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
        notify "Adding VSCode repository";
        curl "https://packages.microsoft.com/keys/microsoft.asc" | gpg --dearmor > microsoft.gpg;
        sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/;
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list;
    fi
}

# Sublime
##########################################################
repoSublime() {
    if [[ ! -f /etc/apt/sources.list.d/sublime-text.list ]]; then
        notify "Adding Sublime Text repository";
        curl -fsSL "https://download.sublimetext.com/sublimehq-pub.gpg" | sudo apt-key add -;
        echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list;
    fi
}

# Remmina
##########################################################
repoRemmina() {
    if [[ ! -f /etc/apt/sources.list.d/remmina.list ]]; then
        notify "Adding Remmina repository";
        sudo touch /etc/apt/sources.list.d/remmina.list;
        echo "deb http://ftp.debian.org/debian ${versionDeb}-backports main" | sudo tee --append "/etc/apt/sources.list.d/${versionDeb}-backports.list" >> /dev/null
    fi
}

# Google Cloud SDK
##########################################################
repoGoogleSdk() {
    if [[ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]]; then
        notify "Adding GCE repository";
        CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)";
        export CLOUD_SDK_REPO;
        echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list;
        curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | sudo apt-key add -;
    fi
}

# MySQL Community Server
##########################################################
repoMySqlServer() {
    if [[ ! -f /var/lib/dpkg/info/mysql-apt-config.list ]]; then
        notify "Adding MySQL Community Server repository";
        curlToFile "https://dev.mysql.com/get/mysql-apt-config_0.8.11-1_all.deb" "mysql.deb";
        sudo dpkg -i mysql.deb;
        rm mysql.deb -f;
    fi
}

###############################################################
## INSTALLATION
###############################################################

# Debian Software Center
installSoftwareCenter() {
    sudo apt install -y gnome-software gnome-packagekit;
}

# Git
##########################################################
installGit() {
    title "Installing Git";
    sudo apt install -y git;
    breakLine;
}

# Node
##########################################################
installNode() {
    title "Installing Node ${VERSION_NODE}";
    curl -L "https://deb.nodesource.com/setup_${VERSION_NODE}.x" | sudo -E bash -;
    sudo apt install -y nodejs npm;

    if [[ ${versionDeb} = "stretch" ]]; then
      sudo chown -R "$(whoami)" /usr/lib/node_modules;
      sudo chmod -R 777 /usr/lib/node_modules;
    fi

    if [[ ${versionDeb} = "buster" ]]; then
      sudo chown -R "$(whoami)" /usr/share/npm/node_modules;
      sudo chmod -R 777 /usr/share/npm/node_modules;
    fi

    sudo npm install -g n;
    sudo n ${VERSION_NODE};
    
    IS_INSTALLED_NODE=1;
    breakLine;
}

# React Native
##########################################################
installReactNative() {
    title "Installing React Native";
    sudo npm install -g create-react-native-app;
    breakLine;
}

# Cordova
##########################################################
installCordova() {
    title "Installing Apache Cordova";
    sudo npm install -g cordova;
    breakLine;
}

# Phonegap
##########################################################
installPhoneGap() {
    title "Installing Phone Gap";
    sudo npm install -g phonegap;
    breakLine;
}

# Webpack
##########################################################
installWebpack() {
    title "Installing Webpack";
    sudo npm install -g webpack;
    breakLine;
}

# PHP
##########################################################
installPhp() {
    title "Installing PHP ${VERSION_PHP}";
    sudo apt install -y php${VERSION_PHP} php${VERSION_PHP}-{bcmath,cli,common,curl,dev,gd,intl,mbstring,mysql,sqlite3,xml,zip} php-pear php-memcached php-redis;
    sudo apt install -y libphp-predis php-xdebug php-ds;
    php --version;

    sudo pecl install igbinary ds;
    IS_INSTALLED_PHP=1;
    breakLine;
}

# Werf
##########################################################
installWerf() {
    title "Installing Werf v${VERSION_WERF} with Helm v${VERSION_HELM}";
    curl -L "https://dl.bintray.com/flant/werf/v${VERSION_WERF}/werf-linux-amd64-v${VERSION_WERF}" -o /tmp/werf;
    chmod +x /tmp/werf;
    sudo mv /tmp/werf /usr/local/bin/werf;
    curl "https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-${VERSION_HELM}" | bash;
    breakLine;
}

# Python
##########################################################
installPython() {
    title "Installing Python3 with PIP";
    sudo apt install -y build-essential libssl-dev libffi-dev python-dev python3-pip;
    sudo ln -s /usr/bin/pip3 /usr/bin/pip;

    if [[ -f .bashrc ]]; then
        sed -i '/export PATH/d' ~/.bashrc;
        echo "export PATH=\"$PATH:/usr/local/bin/python\"" | tee -a ~/.bashrc;
    fi
    if [[ -f .zshrc ]]; then
        sed -i '/export PATH/d' ~/.zshrc;
        echo "export PATH=\"$PATH:/usr/local/bin/python\"" | tee -a ~/.zshrc;
    fi

    IS_INSTALLED_PYTHON=1;
    breakLine;
}

# GoLang
##########################################################
installGoLang() {
    title "Installing GoLang ${VERSION_GO}";
    curlToFile "https://dl.google.com/go/go${VERSION_GO}.linux-amd64.tar.gz" "go.tar.gz";
    tar xvf go.tar.gz;

    if [[ -d /usr/local/go ]]; then
        sudo rm -rf /usr/local/go;
    fi

    sudo mv go /usr/local;
    rm go.tar.gz -f;
   
    if [[ -f .bashrc ]]; then
        sed -i '/export PATH/d' ~/.bashrc;
        echo "export GOROOT=\"/usr/local/go\"" | tee -a ~/.bashrc;
        echo "export GOPATH=\"$HOME/go\"" | tee -a ~/.bashrc;
        echo "export PATH=\"$PATH:/usr/local/go/bin:$GOPATH/bin\"" | tee -a ~/.bashrc;
    fi
    
    if [[ -f .zshrc ]]; then
        sed -i '/export PATH/d' ~/.zshrc;
        echo "export GOROOT=\"/usr/local/go\"" | tee -a ~/.zshrc;
        echo "export GOPATH=\"$HOME/go\"" | tee -a ~/.zshrc;
        echo "export PATH=\"$PATH:/usr/local/go/bin:$GOPATH/bin\"" | tee -a ~/.zshrc;
    fi
    
    export PATH=$PATH:/usr/local/go/bin;
    
    mkdir "${GOPATH}";
    sudo chown -R root:root "${GOPATH}";

    IS_INSTALLED_GO=1;
    breakLine;
}

# Yarn
##########################################################
installYarn() {
    title "Installing Yarn";
    sudo apt install -y yarn;
    breakLine;
}

# Memcached
##########################################################
installMemcached() {
    title "Installing Memcached";
    sudo apt install -y memcached;
    sudo systemctl start memcached;
    sudo systemctl enable memcached;
    breakLine;
}

# Redis
##########################################################
installRedis() {
    title "Installing Redis";
    sudo apt install -y redis-server;
    sudo systemctl start redis;
    sudo systemctl enable redis;
    breakLine;
}

# Composer
##########################################################
installComposer() {
    title "Installing Composer";
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');";
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer;
    sudo rm /tmp/composer-setup.php;
    breakLine;
}

# Laravel Installer
##########################################################
installLaravel() {
    title "Installing Laravel Installer";
    composer global require "laravel/installer";
    if [[ -f .bashrc ]]; then
        sed -i '/export PATH/d' ~/.bashrc;
        echo "export PATH=\"$PATH:$HOME/.config/composer/vendor/bin\"" | tee -a ~/.bashrc;
    fi
    if [[ -f .zshrc ]]; then
        sed -i '/export PATH/d' ~/.zshrc;
        echo "export PATH=\"$PATH:$HOME/.config/composer/vendor/bin\"" | tee -a ~/.zshrc;
    fi
    
    breakLine;
}

# SQLite Browser
##########################################################
installSqLite() {
    title "Installing SQLite Browser";
    sudo apt install -y sqlitebrowser;
    breakLine;
}

# DBeaver
##########################################################
installDbeaver() {
    title "Installing DBeaver SQL Client";
    curlToFile "https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb" "dbeaver.deb";
    sudo apt install -y -f ~/dbeaver.deb;
    sudo rm ~/dbeaver.deb;
    breakLine;
}

# Redis Desktop Manager
##########################################################
installRedisDesktopManager() {
    title "Installing Redis Desktop Manager";
    sudo snap install redis-desktop-manager;
    breakLine;
}

# Docker
##########################################################
installDocker() {
    title "Installing Docker CE with Docker Compose";
    sudo apt install -y docker-ce;
    curlToFile "https://github.com/docker/compose/releases/download/${VERSION_DOCKERCOMPOSE}/docker-compose-$(uname -s)-$(uname -m)" "/usr/local/bin/docker-compose";
    sudo chmod +x /usr/local/bin/docker-compose;

    sudo groupadd docker;
    sudo usermod -aG docker "${USER}";

    notify "Install a separate runc environment?";

    while true; do
        read -p "Recommended on chromebooks (y/n)" yn
        case ${yn} in
            [Yy]* )
                if [[ ${IS_INSTALLED_GO} -ne 1 ]] && [[ "$(command -v go)" == '' ]]; then
                    breakLine;
                    installGoLang;
                fi

                sudo sed -i -e 's/ExecStartPre=\/sbin\/modprobe overlay/#ExecStartPre=\/sbin\/modprobe overlay/g' /lib/systemd/system/containerd.service;

                sudo apt install libseccomp-dev -y;
                go get -v "github.com/opencontainers/runc";

                cd "${GOPATH}/src/github.com/opencontainers/runc" || exit;
                export GO111MODULE=on;
                make BUILDTAGS='seccomp apparmor';

                sudo cp "${GOPATH}/src/github.com/opencontainers/runc/runc" /usr/local/bin/runc-master;

                curlToFile "${REPO_URL}docker/daemon.json" /etc/docker/daemon.json;
                sudo systemctl daemon-reload;
                sudo systemctl restart containerd.service;
                sudo systemctl restart docker;
                
                cd ~ || exit;
                rm -rf
            break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    breakLine;
}

# Kubernetes
##########################################################
installKubernetes() {
    title "Installing Kubernetes";
    sudo apt install -y kubectl;
    breakLine;
}

# Sops
##########################################################
installSops() {
    title "Installing Sops v${VERSION_SOPS}";
    wget -O sops_${VERSION_SOPS}_amd64.deb "https://github.com/mozilla/sops/releases/download/${VERSION_SOPS}/sops_${VERSION_SOPS}_amd64.deb";
    sudo dpkg -i sops_${VERSION_SOPS}_amd64.deb;
    sudo rm sops_${VERSION_SOPS}_amd64.deb;
    breakLine;
}

# Wine
##########################################################
installWine() {
    title "Installing Wine & Mono";
    sudo apt install -y cabextract;
    sudo apt install -y --install-recommends winehq-stable;
    sudo apt install -y mono-vbnc winbind;

    notify "Installing WineTricks";
    curlToFile "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" "winetricks";
    sudo chmod +x ~/winetricks;
    sudo mv ~/winetricks /usr/local/bin;

    notify "Installing Windows Fonts";
    winetricks allfonts;

    notify "Installing Smooth Fonts for Wine";
    curlToFile ${REPO_URL}"wine_fontsmoothing.sh" "wine_fontsmoothing";
    sudo chmod +x ~/wine_fontsmoothing;
    sudo ./wine_fontsmoothing;
    clear;

    notify "Installing Royale 2007 Theme";
    curlToFile "http://www.gratos.be/wincustomize/compressed/Royale_2007_for_XP_by_Baal_wa_astarte.zip" "Royale_2007.zip";

    sudo chown -R "$(whoami)" ~/;
    mkdir -p ~/.wine/drive_c/Resources/Themes/;
    unzip ~/Royale_2007.zip -d ~/.wine/drive_c/Resources/Themes/;

    notify "Cleaning up...";
    rm ~/wine_fontsmoothing -f;
    rm ~/Royale_2007.zip -f;
}

# Postman
##########################################################
installPostman() {
    title "Installing Postman";
    curlToFile "https://dl.pstmn.io/download/latest/linux64" "postman.tar.gz";
    sudo tar xfz ~/postman.tar.gz;

    sudo rm -rf /opt/postman/;
    sudo mkdir /opt/postman/;
    sudo mv ~/Postman*/* /opt/postman/;
    sudo rm -rf ~/Postman*;
    sudo rm -rf ~/postman.tar.gz;
    sudo ln -s /opt/postman/Postman /usr/bin/postman;

    notify "Adding desktop file for Postman";
    curlToFile ${REPO_URL}"desktop/postman.desktop" "/usr/share/applications/postman.desktop";
    breakLine;
}

# Atom IDE
##########################################################
installAtom() {
    title "Installing Atom IDE";
    sudo apt install -y atom;
    breakLine;
}

# VS Code
##########################################################
installVsCode() {
    title "Installing VS Code IDE";
    sudo apt install -y code;
    breakLine;
}

# Sublime Text
##########################################################
installSublime() {
    title "Installing Sublime Text";
    sudo apt install -y sublime-text;
    sudo pip install -U CodeIntel;

    sudo chown -R "$(whoami)" ~/;

    mkdir -p ~/.config/sublime-text-3/Packages/User;

    notify "Adding package control for sublime";
    wget "https://packagecontrol.io/Package%20Control.sublime-package" -o ".config/sublime-text-3/Installed Packages/Package Control.sublime-package";

    notify "Adding pre-installed packages for sublime";
    curlToFile "${REPO_URL}settings/PackageControl.sublime-settings" ".config/sublime-text-3/Packages/User/Package Control.sublime-settings";

    notify "Applying default preferences to sublime";
    curlToFile "${REPO_URL}settings/Preferences.sublime-settings" ".config/sublime-text-3/Packages/User/Preferences.sublime-settings";

    notify "Installing additional binaries for sublime auto-complete";
    curlToFile "https://github.com/emmetio/pyv8-binaries/raw/master/pyv8-linux64-p3.zip" "bin.zip";

    sudo mkdir -p ".config/sublime-text-3/Installed Packages/PyV8/";
    sudo unzip ~/bin.zip -d ".config/sublime-text-3/Installed Packages/PyV8/";
    sudo rm ~/bin.zip;

    IS_INSTALLED_SUBLIME=1;
    breakLine;
}

# PHP Storm
##########################################################
installPhpStorm() {
    title "Installing PhpStorm IDE ${VERSION_PHPSTORM}";
    curlToFile "https://download.jetbrains.com/webide/PhpStorm-${VERSION_PHPSTORM}.tar.gz" "phpstorm.tar.gz";
    sudo tar xfz ~/phpstorm.tar.gz;

    sudo rm -rf /opt/phpstorm;
    sudo mkdir -p /opt/phpstorm;
    sudo mv ~/PhpStorm-*/* /opt/phpstorm/;
    sudo rm -rf ~/phpstorm.tar.gz;
    sudo rm -rf ~/PhpStorm-*;

    notify "Adding desktop file for PhpStorm";
    curlToFile ${REPO_URL}"desktop/jetbrains-phpstorm.desktop" "/usr/share/applications/jetbrains-phpstorm.desktop";
    breakLine;
}

# Remmina
##########################################################
installRemmina() {
    title "Installing Remmina Client";
    sudo apt install -t "${versionDeb}-backports" remmina remmina-plugin-rdp remmina-plugin-secret -y;
    breakLine;
}

# Google Cloud SDK
##########################################################
installGoogleSdk() {
    title "Installing Google Cloud SDK";
    sudo apt install -y google-cloud-sdk;
    breakLine;
}

# Popcorn Time
##########################################################
installPopcorn() {
    title "Installing Popcorn Time v${VERSION_POPCORNTIME}";
    sudo apt install -y libnss3 vlc;

    if [[ -d /opt/popcorn-time ]]; then
        sudo rm -rf /opt/popcorn-time;
    fi

    curlToFile "https://github.com/popcorn-official/popcorn-desktop/releases/download/v${VERSION_POPCORNTIME}/Popcorn-Time-${VERSION_POPCORNTIME}-amd64.deb" 'popcorn.deb';
    sudo apt install ./popcorn.deb;
    rm -f popcorn.deb;
    breakLine;
}

# ZSH
##########################################################
installZsh() {
    title "Installing ZSH Terminal Plugin";
    sudo apt install -y zsh fonts-powerline;
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)";

    if [[ -f "${HOME}/.zshrc" ]]; then
        rm "${HOME}/.zshrc";
    fi

    echo '/bin/zsh' >> ~/.bashrc;
    sudo chsh -s "$(which zsh)" "$(whoami)";

    IS_INSTALLED_ZSH=1;
    breakLine;
}

# MySql Community Server
##########################################################
installMySqlServer() {
    title "Installing MySql Community Server";
    sudo apt install -y mysql-server;
    sudo systemctl enable mysql;
    sudo systemctl start mysql;

    IS_INSTALLED_MYSQLSERVER=1;
    breakLine;
}

# Locust
##########################################################
installLocust() {
  title "Installing Locust";
  sudo pip3 install locust;
  breakLine;
}

# JAVA
##########################################################
installJAVA() {
  title "Installing JAVA";
  sudo apt update;
  sudo apt install -y default-jdk;
  java -version;
  breakLine;
}


# Maven
##########################################################
installMVN() {
  title "Installing Maven";
  sudo apt update;
  sudo apt install -y maven;
  mvn -version;
  breakLine;
}

# Netbeans
##########################################################
installNetbeans() {
  installJAVA;;
  title "Installing Netbeans";
  sudo apt update;
  sudo apt install -y netbeans;
  
  breakLine;
}


###############################################################
## MAIN PROGRAM
###############################################################
sudo apt install -y dialog;

cmd=(dialog --backtitle "Debian Developer Container - USAGE: <space> un/select options & <enter> start installation." \
--ascii-lines \
--clear \
--nocancel \
--separate-output \
--checklist "Select installable packages:" 42 50 50);

options=(
    01 "Git" on
    02 "Node v${VERSION_NODE} with npm" on
    03 "PHP v${VERSION_PHP} with PECL" on
    04 "Werf v${VERSION_WERF} with Helm v${VERSION_HELM}" on
    05 "Python" on
    06 "GoLang v${VERSION_GO}" off
    07 "Yarn (package manager)" off
    08 "Composer (package manager)" on
    09 "React Native" off
    10 "Apache Cordova" off
    11 "Phonegap" off
    12 "Webpack" off
    13 "Memcached server" off
    14 "Redis server" off
    15 "Docker CE (with docker compose)" on
    16 "Kubernetes (kubectl)" on
    17 "Sops v${VERSION_SOPS}" on
    18 "Postman" on
    19 "Laravel installer" on
    20 "Wine" off
    21 "MySql Community Server" off
    22 "SQLite (database tool)" off
    23 "DBeaver (database tool)" off
    24 "Redis Desktop Manager" off
    25 "Atom IDE" off
    26 "VS Code IDE" off
    27 "Sublime Text IDE" off
    28 "PhpStorm IDE v${VERSION_PHPSTORM}" on
    29 "Software Center" on
    30 "Remmina (remote desktop client)" off
    31 "Google Cloud SDK" on
    32 "Popcorn Time v${VERSION_POPCORNTIME}" off
    33 "ZSH Terminal Plugin" off
    34 "Locust (http load tester)" off
    35 "Java" on
    36 "MVN" on
    37 "Netbeans" on
);

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty);

clear;

# Preparation
##########################################################
title "Installing Pre-Requisite Packages";
    cd ~/ || exit;
    sudo chown -R "$(whoami)" ~/
    sudo apt update;
    sudo apt dist-upgrade -y;

    sudo apt install -y ca-certificates \
    apt-transport-https \
    software-properties-common \
    wget \
    curl \
    htop \
    mlocate \
    gnupg2 \
    cmake \
    libssh2-1-dev \
    libssl-dev \
    nano \
    vim \
    snapd;

    if [[ ${versionDeb} = "stretch" ]]; then
      sudo apt install -y preload gksu;
      sudo rm /usr/share/applications/gksu.desktop;
    fi

    sudo updatedb;
breakLine;

title "Adding Repositories";
    for choice in ${choices}
    do
        case ${choice} in
            03) repoPhp ;;
            08) repoPhp ;;
            07) repoYarn ;;
            15) repoDocker ;;
            16) repoKubernetes ;;
            19) repoPhp ;;
            20) repoWine;;
            21) repoMySqlServer ;;
            25) repoAtom ;;
            26) repoVsCode ;;
            27) repoSublime ;;
            30) repoRemmina ;;
            31) repoGoogleSdk ;;
        esac
    done
    notify "Required repositories have been added...";
breakLine;

title "Updating apt";
    sudo apt update;
    notify "The apt package manager is fully updated...";
breakLine;

for choice in ${choices}
do
    case ${choice} in
        01) installGit ;;
        02) installNode ;;
        03) installPhp ;;
        04) installWerf ;;
        05) installPython ;;
        06) installGoLang ;;
        07) installYarn ;;
        08)
            if [[ ${IS_INSTALLED_PHP} -ne 1 ]]; then installPhp; fi
            installComposer;
        ;;
        09)
            if [[ ${IS_INSTALLED_NODE} -ne 1 ]]; then installNode; fi
            installReactNative;
        ;;
        10)
            if [[ ${IS_INSTALLED_NODE} -ne 1 ]]; then installNode; fi
            installCordova;
        ;;
        11)
            if [[ ${IS_INSTALLED_NODE} -ne 1 ]]; then installNode; fi
            installPhoneGap;
        ;;
        12)
            if [[ ${IS_INSTALLED_NODE} -ne 1 ]]; then installNode; fi
            installWebpack;
        ;;
        13) installMemcached ;;
        14) installRedis ;;
        15) installDocker ;;
        16) installKubernetes ;;
        17)
            if [[ ${IS_INSTALLED_GO} -ne 1 ]]; then installGoLang; fi
            installSops;
        ;;
        18) installPostman ;;
        19)
            if [[ ${IS_INSTALLED_PHP} -ne 1 ]]; then installPhp; fi
            installLaravel;
        ;;
        20) installWine ;;
        21) installMySqlServer ;;
        22) installSqLite ;;
        23) installDbeaver ;;
        24) installRedisDesktopManager ;;
        25) installAtom ;;
        26) installVsCode ;;
        27)
            if [[ ${IS_INSTALLED_PYTHON} -ne 1 ]]; then installPython; fi
            installSublime;
        ;;
        28) installPhpStorm ;;
        29) installSoftwareCenter ;;
        30) installRemmina ;;
        31) installGoogleSdk ;;
        32) installPopcorn ;;
        33) installZsh ;;
        34)
            if [[ ${IS_INSTALLED_PYTHON} -ne 1 ]]; then installPython; fi
            installLocust;
        ;;
        35) installJAVA ;;
        36) installMVN ;;
        37) installNetbeans ;;
    esac
done

# Clean
##########################################################
title "Finalising & Cleaning Up...";
    sudo chown -R "$(whoami)" ~/;
    sudo apt --fix-broken install -y;
    sudo apt autoremove -y --purge;
breakLine;

notify "Great, the installation is complete =)";
echo "If you want to install further tool in the future you can run this script again.";

###############################################################
## POST INSTALLATION ACTIONS
###############################################################
if [[ ${IS_INSTALLED_ZSH} -eq 1 ]]; then
    breakLine;
    notify "ZSH Plugin Detected..."

    cd ~/ || exit;
    curlToFile ${REPO_URL}"zsh/.zshrc" ".zshrc";

    source ~/.zshrc;

    echo "";
    echo "If the zsh plugin does not take effect you can manually activate it by adding /bin/zsh to you .bashrc file. ";
    echo "Further information & documentation on the ZSH plugin: https://github.com/robbyrussell/oh-my-zsh";
fi

if [[ ${IS_INSTALLED_SUBLIME} -eq 1 ]]; then
    breakLine;
    notify "Sublime Text Detected..."
    echo "";
    echo "To complete the Sublime Text installation make sure to install the 'Package Control' plugin when first running Sublime."
    echo "";
fi

if [[ ${IS_INSTALLED_MYSQLSERVER} -eq 1 ]]; then
    breakLine;
    notify "MySql Community Server Detected..."
    echo "";
    echo "If you want to harden your MySql installation run: mysql-secure-install"
    echo "";
fi

echo "";
