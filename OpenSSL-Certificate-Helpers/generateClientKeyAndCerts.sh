#!/bin/sh

deleteDecryptedPrivateKey=false
useExistingPrivateKey=false         # This must have the same password as the password field below and the keypath must be correct
printCSR=true

password="Password1!"     # Must be more than 4 characters
encryptedClientKeyPath="client-encrpyted.key"
decryptedClientKeyPath="client-decrpyted.key"
csrpath="client.csr"
clientCertPath="client.cert"
numberOfDaysValid="50000"
decryptedCaKeyPath="ca.key"
caCertPath="ca.cert"

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
    echo "using existing private key: $encryptedClientKeyPath"
fi

if ! $useExistingPrivateKey
then
    # generates private key
    openssl genpkey -algorithm "$algorithm" "-$cypher" -out "$encryptedClientKeyPath" -pass pass:"$password" -pkeyopt rsa_keygen_bits:"$keylength"
fi

# create temporary private key
openssl rsa -in "$encryptedClientKeyPath" -passin "pass:$password" -out "$decryptedClientKeyPath"

# generate a CSR
openssl req -new -subj "$csrSubjects" -key "$decryptedClientKeyPath" -out "$csrpath"

# This can be used to create self signed certificates
# openssl x509 -req -in "$csrpath" -signkey "$decryptedClientKeyPath" -out "$clientCertPath" -days "$numberOfDaysValid" -addtrust "clientAuth"

# clean up temp files
if $deleteDecryptedPrivateKey
then 
    rm $decryptedClientKeyPath
fi

if $printCSR
then
    openssl req -in "$csrpath" -text
fi

echo "generating client certificate..."

# This can be used to generate a certificate signed by another certificate authority (for use with mutually authenticated communication)
openssl x509 -req -in "$csrpath" -CA "$caCertPath" -CAkey "$decryptedCaKeyPath" -CAcreateserial -out "$clientCertPath" -days "$numberOfDaysValid" -addtrust "clientAuth"


cat $caCertPath >> $clientCertPath

echo "done"