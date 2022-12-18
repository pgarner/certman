#!/bin/zsh
#
# Generate SSL certificates
#
# Phil Garner, December 2022
#

#
# This script does three things:
# 1. Generates a root certficate
# 2. Generates a host certificate signing request
# 3. Uses the root certificate to sign the signing request
#
# References
# https://www.baeldung.com/linux/openssl-extract-certificate-info
# https://node-security.com/posts/openssl-creating-a-ca/
# https://node-security.com/posts/openssl-creating-a-host-certificate/
#

# Generate a CA (root) certificate
rootcnf=root.cnf      # Configuration for root certificate generation
rootkey=root-key.pem  # The (private) CA key
rootcrt=root-crt.pem  # The (public) root CA certificate

# There should be just one root certificate covering as many services as
# necessary, so this should not overwrite an existing certificate (pair)
if [[ ! -e $rootcrt ]]
then
    openssl genrsa -out $rootkey 4096  # Default is 2048-bit

    cat > $rootcnf << EOF
basicConstraints = CA:TRUE
keyUsage = cRLSign, keyCertSign

[req]
distinguished_name = req_dn
prompt = no

[req_dn]
C   = CH
L   = Martigny
CN  = Phil Garner Root CA
EOF

    sslargs=(
        -x509            # Output a Certificate instead of a Signing Request
        -sha512          # Hash used to sign
        -nodes           # Unencrypted
        -out $rootcrt    # Output file
        -key $rootkey    # Private key
        -days 7307       # Valid for 20 years
        -config $rootcnf # Configuration
    )
    openssl req -new $sslargs
fi

# Dump the root certificate
print Certificate $rootcrt is:
openssl x509 -in $rootcrt -noout -issuer -nameopt sep_multiline -dates


# Use the CA to sign a new certificate pair
hostcnf=host.cnf      # Configuration for host signing request
hostext=host-ext.cnf  # Configuration for hots certificate generation
hostkey=host-key.pem  # The (private) host key
hostcsr=host-csr.pem  # The certificate signing request
hostcrt=host-crt.pem  # The (public) host certificate

openssl genrsa -out $hostkey  # Default is 2048-bit

# Following the "Node Security" page, the [alt_names] are here too, eventhough
# they get overwritten by the signing process.  Otherwise the resulting
# certificate is invalid.  Perhaps just the field is necessary?
cat > $hostcnf << EOF
[req]
default_md = sha512
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[req]
distinguished_name = req_dn
req_extensions = req_ext
prompt = no

[req_dn]
C   = CH
L   = Martigny
CN  = Phil Garner Host Cert

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = pooh
DNS.2 = localhost
IP.1 = 192.168.0.3
IP.2 = 127.0.0.1
IP.3 = ::1
EOF

sslargs=(
    -sha512
    -nodes
    -key $hostkey
    -out $hostcsr
    -config $hostcnf
)
openssl req -new $sslargs

cat > $hostext << EOF
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "Host Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = pooh
DNS.2 = localhost
IP.1 = 192.168.0.3
IP.2 = 127.0.0.1
IP.3 = ::1
EOF

sslargs=(
    -sha512
    -days 365
    -in $hostcsr
    -CA $rootcrt
    -CAkey $rootkey
    -CAcreateserial
    -out $hostcrt
    -extfile $hostext
)
openssl x509 -req $sslargs

# Dump the resulting certificate
print Certificate $hostcrt is:
openssl x509 -in $hostcrt -noout -subject -issuer -nameopt sep_multiline -dates
