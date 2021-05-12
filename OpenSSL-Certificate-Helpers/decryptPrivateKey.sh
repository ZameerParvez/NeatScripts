#!/bin/sh
echo "replace the keypath field in the script with the path of the encrypted private key"
echo "replace the password field in the script with the password used to encrypt the private key"
password=""     # Must be more than 4 characters
keypath="encryptedPrivateKey"
decryptedKeyPath="decryptedPrivateKey"

openssl rsa -in "$keypath" -passin "pass:$password" -out "$decryptedKeyPath"

echo "The decrypted private key is at $decryptedKeyPath"