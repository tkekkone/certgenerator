#!/bin/bash
function failcertmgr
{
	echo "No certmgr found. Not added to mono store."
	exit 0
}

if [ $# -ne 4 ]; then
	echo "Not enough arguments given."
	echo "Usage genmonocert.sh ca.crt ca.key <capassword> <serverkeypasswd>"
	if [ $# -eq 2 ]; then
		echo "Guessing you want to generate ca cert too"
		echo "paramters you gave: $1 $2"
		serverkey=$2
		capass=$1
		genca=1
	else
		exit 1
	fi
else
	capass=$3
	serverkey=$4
	cacertfile=$1
	cafile=$2
fi
echo "server key pass: $serverkey"
echo "ca key pass $capass"
echo "paramters you gave: $1 $2 $3"

if [ -n $genca ]; then
	cafile="ca.key"
	cacertfile="ca.crt"
	echo "Generating ssl ca certificate because it was not given as parameter"
	openssl genrsa -passout pass:$capass -des3 -out $cafile 4096
	openssl req -passin pass:$capass -new -subj "/C=FI/ST=Default/L=Silly/O=Values/OU=Dontmatter/CN=$(hostname)" -x509 -days 365 -key ca.key -out $cacertfile
fi
echo "Generating ssl certificate"
if [ -n $serverkey ]; then
	echo "Generating server key without passphrase"
	openssl genrsa -out servercert.key 4096
	openssl req -new -key servercert.key -out servercert.csr -subj "/CN=$(hostname)"	
else
	openssl genrsa -des3 -passout pass:$serverkey -out servercert.key 4096
	openssl req -new -key servercert.key -passin pass:$serverkey -out servercert.csr -subj "/CN=$(hostname)"
fi
openssl x509 -req -days 365 -extfile <(printf "subjectAltName=DNS:localhost,DNS:$(hostname)") -in servercert.csr -CA $cacertfile -passin pass:$capass -CAkey $cafile -set_serial 01 -out servercert.cer
openssl pkcs12 -export -passin pass:$serverkey -clcerts -in servercert.cer -inkey servercert.key -out servercert.p12 -passout pass:$serverkey -name $(hostname)
echo "#######################################"
echo "Your certificate name is: $(hostname) add that to config to use form mono store"
echo "#######################################"
certmgr || failcertmgr
echo "Adding to mono store"
sudo certmgr -importKey -c -v -p $serverkey -m My servercert.p12 || failcertmgr
sudo certmgr -add -c -m My servercert.cer || failcertmgr
echo "Added to store"
