#!/bin/bash

p12file=""
outfile="cert_easyroam.pem"
outdir="$PWD/easyroam_certs"
function help(){
    helpHeader
    printf "\n"
    helpBody
}

function printVars(){
    format="%-10s %-20s \n"
    printf "Current configuration:\n"
    printf "$format" "p12:" "$p12file"
    printf "$format" "outfile:" "$outfile"
    printf "$format" "outdir:" "$outdir"
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
    printf "$formatOptions" "-o --output" "name for merged certificate" "(optional, default=$outfile)"
    printf "$formatOptions" "-d --directory" "path for certificates" "(optional, default=$outdir)"
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
        printf $p12file
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
        shift; outfile=$1
        ;;
    -d | --directory )
         shift; outdir=$1
    ;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi


checkRequired
isValid=$?

if [[ $isValid -eq 1 ]]; then
    rm -rf $outdir
    if [[ ! -e $outdir ]]; then
        mkdir $outdir
    fi    

    printVars
    printf "Do you want to continue? (y) if yes \n"
    read input
    if [[ $input != "y" ]]; then
        printf "Exit procedure\n"
        exit
    fi

    client_cert="easyroam_client_cert.pem"
    private_cert="easyroam_client_key.pem"
    root_cert="easyroam_root_ca.pem"
    certs=("$client_cert" "$private_cert" "$root_cert")

    # client certificate
    printf "Extracting client certifacte ... \n"
    openssl pkcs12 -in $p12file -legacy -nokeys > $outdir/$client_cert
    #private certificate
    printf "Extracting private certificate ...\n"
    openssl pkcs12 -legacy -in $p12file -nodes -nocerts | openssl rsa -aes256 -out $outdir/$private_cert
    #root certificate
    printf "Extracting root certificate ...\n"
    openssl pkcs12 -in $p12file -cacerts > $outdir/$root_cert
    printf "Certificates extracted ...\n"
    printf "Merging certs $certs into one file ... \n"
fi 