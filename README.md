# To query a certificate

Basic operations are
```
openssl x509 -in cert.pem -noout -subject
openssl x509 -in cert.pem -noout -issuer
openssl x509 -in cert.pem -noout -dates
```
Or to format nicely
```
openssl x509 -in cert.pem -noout -subject -nameopt sep_multiline
```

A couple of root cert examples:
```
% openssl x509 -in Idiap_2016_Root-cacert.pem -noout -issuer -nameopt sep_multiline 
issuer=
    C=CH
    ST=VS
    L=Martigny
    O=Idiap Research Institute
    OU=PKI
    CN=Idiap Root CA 2016
    emailAddress=pki@idiap.ch
```
and SwissSign
```
% openssl x509 -in /etc/ssl/certs/SwissSign_Gold_CA_-_G2.pem -noout -issuer -nameopt sep_multiline
issuer=
    C=CH
    O=SwissSign AG
    CN=SwissSign Gold CA - G2
```

# To add a certificate

On arch:
```
trust anchor root-crt.pem
```
