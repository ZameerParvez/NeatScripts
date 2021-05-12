#!/bin/sh

deleteDecryptedPrivateKey=false
useExistingPrivateKey=true         # This must have the same password as the password field below and the keypath must be correct
printCSR=true

password="Password1!"     # Must be more than 4 characters
keypath="encryptedPrivateKey"

csrpath="TESTCSR"
algorithm="RSA"
cypher="aes256"
keylength="2048"

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

if $useExistingPrivateKey
then
    echo "using existing private key: $keypath"
fi

if ! $useExistingPrivateKey
then
    # generates private key
    openssl genpkey -algorithm "$algorithm" "-$cypher" -out "$keypath" -pass pass:"$password" -pkeyopt rsa_keygen_bits:"$keylength"
fi

# create temporary private key
tempDecryptedKeyPath="decryptedPrivateKey"

openssl rsa -in "$keypath" -passin "pass:$password" -out "$tempDecryptedKeyPath"

# generate a CSR
openssl req -new -subj "$csrSubjects" -key "$tempDecryptedKeyPath" -out "$csrpath"

# clean up temp files
if $deleteDecryptedPrivateKey
then 
    rm $tempDecryptedKeyPath
fi

if $printCSR
then
    openssl req -in "$csrpath" -text
fi

echo "The generated CSR is at: $csrpath"