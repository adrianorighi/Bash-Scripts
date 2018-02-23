#!/bin/bash

#---------------------------------------------------#
#   Shell Script to auto configure nginx on Ubuntu  #
#        Run on Ubuntu 14.04 LTS or Later           #
#           Created by Adriano Righi                #
#               adrianorighi.com                    #
#---------------------------------------------------#

if [ $USER != 'root' ]
    then
        dialog --backtitle "Nginx VirtualHost" --title "Erro!" --clear --msgbox "Esse script funciona apenas como root ou sudo." 8 40
        exit 1;
fi

# Variáveis
VHOST=''
DIR=''

# Create a temp dir
TMP=${TMPDIR-/tmp}
    TMP=$TMP/righi.$RANDOM.$RANDOM.$RANDOM.$$ # Using a random name
    (umask 077 & mkdir "$TMP") || {
        dialog --backtitle "Nginx VirtualHost" --title "Erro!" --clear --msgbox "Erro ao criar diretorio temporario." 8 40
        exit 1
    }

# Store menu options selected by the user
INPUT=/$TMP/menu.sh.$$

# Storage file for displaying cal and date command output
OUTPUT=/$TMP/output.sh.$$

# Storage file for install sequence
INSTALL=/$TMP/install.sh.$$

# Storage file for displaying log
LOG=$TMP/installer.log.$$

#
# Display message box
#  $1 -> set msgbox height
#  $2 -> set msgbox width
#  $3 -> set msgbox title
#
function display_output(){
    local h=${1-10}         # box height default 10
    local w=${2-41}         # box width default 41
    local t=${3-Output}     # box title
    dialog --backtitle "Nginx VirtualHost" --title "${t}" --clear --msgbox "$(<$OUTPUT)" ${h} ${w}
}

#
# Display progress bar box
#
function display_progress(){
    local u=${1-10}
    local p=${2-41}
    local q=${3-Output}
    local t=${4-percent}
    dialog --title "Aguarde..." --gauge "${q}" 10 75 "${t}"
}

function createLink {
    # Criando link simbolico
    sudo ln -s /etc/nginx/sites-available/$VHOST.conf /etc/nginx/sites-enabled/$VHOST.conf &> $LOG
}

function createVhost {
    # Criando o arquivo .conf
    echo "server {
        listen   80;

        root $DIR;

        index index.php index.html index.htm;

        server_name $VHOST;

        # serve static files directly
        location ~* \.(jpg|jpeg|gif|css|png|js|ico|html)$ {
            access_log off;
            expires max;
        }

        # removes trailing slashes (prevents SEO duplicate content issues)
        if (!-d \$request_filename) {
            rewrite ^/(.+)/\$ /\$1 permanent;
        }

        # unless the request is for a valid file (image, js, css, etc.), send to bootstrap
        if (!-e \$request_filename) {
            rewrite ^/(.*)\$ /index.php?/\$1 last;
            break;
        }

        # removes trailing 'index' from all controllers
        if (\$request_uri ~* index/?\$) {
            rewrite ^/(.*)/index/?\$ /\$1 permanent;
        }

        # catch all
        error_page 404 /index.php;
        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)\$;
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi_params;
        }

        location ~ /\.ht {
            deny all;
        }
    }" >> /etc/nginx/sites-available/$VHOST.conf
    createLink;
}

function checkDir {
    if [ ! -d "$DIR" ]; then
        mkdir -p $DIR &> LOG
    fi

    createVhost;
}

function runCreateVHost {
    checkDir;
    for i in $(seq 0 10 100) ; do sleep 1; echo $i | dialog --gauge "Criando arquivo e habilitando virtualHost" 10 50 0; done
}

function getDir {
    # DIR=$(dialog --stdout --title "Selecione o diretório" --fselect /home 14 48)
    DIR=$(dialog --inputbox "Informe o diretório" 10 40  --output-fd 1)
    runCreateVHost;
}

function createVHost {
    VHOST=$(dialog --inputbox "Domínio" 10 40  --output-fd 1)
    getDir;
}

function showLog() {
    cat $LOG > $OUTPUT
    display_output 30 80 "LOG"
}

function testNginx {
    sudo service nginx configtest &> $LOG
    showLog;
}

function restartNginx {
    sudo service nginx restart &> $LOG
    showLog;
}

#
# Set infinite loop
#
while true
do

#
# Display main menu
#
dialog --clear --backtitle "Nginx VirtualHost Script" \
--title "[ M E N U ]" \
--menu "Selecione uma opção\n
\n
Sua distribuição: $(lsb_release -sc)
\n
adrianorighi.com" 15 60 8 \
Create "Criar virtualhost" \
Test "Testar Configs" \
Restart "Reiniciar Nginx" \
ShowLog "Show the log" \
Exit "Exit" 2>"${INPUT}"

menuitem=$(<"${INPUT}")


# Make decision
case $menuitem in
    Create) createVHost;;
    Test) testNginx;;
    Restart) restartNginx;;
    ShowLog) showLog;;
    Exit) break;;
esac

done

#
# Delete if temp files on exit
#
trap "rm -rf $TMP" EXIT SIGHUP SIGINT SIGTERM