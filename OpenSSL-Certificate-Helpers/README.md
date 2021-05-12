# Openssl Certificate Helpers

## About
- this is a collection of scripts that can be used to generate keys, certificates and certificate signing requests
- they are very basic scripts and don't have a UI
- the intended way to use them is to edit specific variable fields inside and run the script to generate the files
- this was originally created for mutually authenticated communication, and it's intended use was to create a CSR

## Details
- "decryptPrivateKey.sh" decrypts the private key given to it and writes it to the path that you set
- "generateCSR.sh" generates a CSR with the given parameters, and also requires a decrypted private key (so it you would likely use it with the result of the previous script)
- "generatePrivateKeyAndCSR.sh" generates a private key and a CSR with that key (This can also be used to generate a CSR from an existing private key, so this should be preferred over the 2 previous scripts)
- "generateClientKeyAndCerts.sh" generates the private key for the client, then creates a CSR with those, and then generates a certificate signed by the given CA (certificate authority) key, so that there is a certificate chain (This requires an existing certificate for the CA and the private key for that)
- the last script can also be used to generate a self signed certificate, if the code under the comment about that is un-commented (I have not tested the validity of self signed certificates, so some options may need to be changed)
