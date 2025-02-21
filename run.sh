#!/bin/sh

set -x

create_cert() {
	if [ ! -f ${SQUID_CERT_DIR}/private.pem ]; then
		echo "Creating certificate..."
		openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 \
			-extensions v3_ca -keyout ${SQUID_CERT_DIR}/private.pem \
			-out ${SQUID_CERT_DIR}/private.pem \
			-subj "/CN=$CERT_CN/O=$CERT_ORG/OU=$CERT_OU/C=$CERT_COUNTRY" -utf8 -nameopt multiline,utf8

		openssl x509 -in ${SQUID_CERT_DIR}/private.pem \
			-outform DER -out ${SQUID_CERT_DIR}/CA.der

		openssl x509 -inform DER -in ${SQUID_CERT_DIR}/CA.der \
			-out ${SQUID_CERT_DIR}/CA.pem
	else
		echo "Certificate is already created, reusing existing certifcates..."
	fi
}
create_cert

# init ssl_db
if [ ! -d /var/cache/squid/ssl_db ]; then
	/usr/lib/squid/security_file_certgen -c -s /var/cache/squid/ssl_db -M 4MB
fi

# force remove pid
if [ -e /var/run/squid/squid.pid ]; then
	rm -f /var/run/squid/squid.pid
fi

# init cache
/usr/sbin/squid -f "${SQUID_CONFIG_FILE}" --foreground -z

# run squid
exec /usr/sbin/squid -f "${SQUID_CONFIG_FILE}" --foreground -YCd 1
