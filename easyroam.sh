#!/bin/bash

p12file=""
outfile="./easyroam_certs"

function help(){
    helpHeader
    printf "\n"
    helpBody
}

function helpHeader(){
    printf "Easyroam Script\n"
    printf "Generates wpa_supplicant config for easyroam\n"
}

function helpBody(){
    formatOptions="\t%-20s %10s %s\n"
    printf "Usage: easyroam.sh [option]\n"
    printf "Options:\n"
    printf "$formatOptions" "-p12 --p12file" "path to p12 file" "(required)"
    printf "$formatOptions" "-o --output" "path to output file" "(optional)"
}

function generateConfig(){
    description='easyroam connection'
    Interface=wlan0
    Connection=wireless
    Security='wpa-configsection'
    IP='dhcp'
    WPAConfigSection=(
        'ssid="eduroam"'
        'key_mgmt=WPA-EAP'
        'eap=TLS'
        'proto=WPA RSN'
        'identity="76673789883214453797@easyroam.realm_der_einrichtung.tld"'   # Hier muss der CN (Common Name) aus dem easyroam Pseudozertifikat stehen!
        'client-cert="/etc/netctl/cert/easyroam_client_cert.pem"'
        'private_key="/etc/netctl/cert/easyroam_client_key.pem"'
        'private_key_passwd="FORYOUREYSEONLY"'
        'ca_cert="/etc/netctl/cert/easyroam_root_ca.pem"'
        'ca_cert2="/etc/netctl/cert/easyroam_root_ca.pem"'
    ) 
}

function checkRequired(){
    missed=0
    formatOptions="%-15s is required\n"
    if [[ -z $p12file ]]; then
        printf "$formatOptions" "-p12 --p12file"
        missed=1
    fi

    printf "\n"
    if [[ missed -eq 1 ]];then
        helpBody
        return 0
    fi
    return 1
}


while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
        -h | --help)
            help
        exit
        ;;
    -p12 | --p12file )
        shift; p12file=$1
        ;;
    -o | --out )
        shift; $outfi=$1
    ;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi


checkRequired
isValid=$?

if [[ $isValid -eq 1 ]]; then

    if [[ ! -e $out ]]; then
        mkdir $out
    fi
    # client certificate
    openssl pkcs12 -in $p12file -legacy -nokeys > $out/easyroam_client_cert.pem
    #private certificate
    openssl pkcs12 -legacy -in $p12file -nodes -nocerts | openssl rsa -aes256 -out $out/easyroam_client_key.pem
    #root certificate
    openssl pkcs12 -in $p12file -cacerts > $out/easyroam_root_ca.pem

fi 