#!/bin/sh

printCSR=true
decryptedKeyPath="client.key"

csrpath="TESTCSR"

# The limits of these fields are determined by the default config, alternate configs can be supplied like the sample config at https://www.openssl.org/docs/man1.1.1/man1/openssl-req.html
commonName="TEST.co.uk"
country="GB"                # Must be 2 characters
state=""
location=""
organisation=""
organisationalUnit=""

# This string is formatted like this to be  compatible with MinGW/MSYS for git bash for windows
csrSubjects="//C=$country\ST=$state\L=$location\O=$organisation\OU=$organisationalUnit\CN=$commonName"

echo "If using a unix system, you will need to uncomment the 'csrSubjects' assignement line"
# csrSubjects="/C=$country/ST=$state/L=$location/O=$organisation/OU=$organisationalUnit/CN=$commonName"

# generate a CSR
openssl req -new -subj "$csrSubjects" -key "$decryptedKeyPath" -out "$csrpath"

if $printCSR
then
    openssl req -in "$csrpath" -text
fi

echo "The generated CSR is at: $csrpath"