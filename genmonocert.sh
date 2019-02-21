#!/bin/bash
if [ $# -ne 4 ]; then
	echo "Not enough arguments given."
	echo "Usage genmonocert.sh ca.crt ca.key <capassword> <serverkeypasswd>"
	exit 1
fi
serverkey=$4
echo "Parameters you gave: $1 $2 $3 $4"
echo "Generating ssl certificate"
openssl genrsa -des3 -passout pass:$serverkey -out servercert.key 4096
openssl req -new -key servercert.key -passin pass:$serverkey -out servercert.csr -subj "/CN=$(hostname)"
openssl x509 -req -days 365 -extfile <(printf "subjectAltName=DNS:localhost,DNS:$(hostname)") -in servercert.csr -CA $1 -passin pass:$3 -CAkey $2 -set_serial 01 -out servercert.cer
openssl pkcs12 -export -passin pass:$serverkey -clcerts -in servercert.cer -inkey servercert.key -out servercert.p12 -passout pass:$serverkey -name $(hostname)
echo "#######################################"
echo "Your certificate name is: $(hostname) use that from mono store"
echo "#######################################"
echo "Adding to mono store. Running with sudo."
sudo certmgr -importKey -c -v -p $serverkey -m My servercert.p12
sudo certmgr -add -c -m My servercert.cer 
