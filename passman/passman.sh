#!/bin/bash

STORE_FILE="${HOME}/.passman/store"
DECRYPT_CMD="gpg2 -dq "$STORE_FILE""
ENCRYPT_KEY="0x12345678"
ENCRYPT_CMD="gpg2 -a --encrypt=- -r "$ENCRYPT_KEY""

if [ -f "${STORE_FILE}" ]
then
	DB="$($DECRYPT_CMD)"
fi

usage() {
	echo "Usage:" >> /dev/stderr
	echo "$0 add <site> [password]" >> /dev/stderr
	echo "$0 gen <site>" >> /dev/stderr
	echo "$0 del <site>" >> /dev/stderr
	echo "$0 show <site>" >> /dev/stderr
	echo "$0 get <site>" >> /dev/stderr
}

add() {
	exists="$(echo "$DB" | grep -G '^'"$1"'	')"
	if [ "$exists" ]
	then
		echo "Site '$1' already exists in database. Delete it first." > /dev/stderr
		exit 3
	fi

	if [ "$2" ]
	then
		newline="${1}	${2}"
	else
		genpwd="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9-_!@#$%^&*()_+{}|:<>?=' | fold -w 20 | grep -e '[^a-zA-Z0-9]' | head -n 1)"
		newline="${1}	${genpwd}"
	fi

	# Don't make shit ugly if the file is brand-spankin'-new.
	if [ -z "$DB" ]
	then
		DB="$newline"
	else
		DB="$(echo "$DB"; echo "$newline")"
	fi
	save='true'
	echo "Added site '$1' to database." > /dev/stderr
}

# Remove password from db.
del() {
	exists="$(echo "$DB" | grep -G '^'"$1"'	')"
	if [ ! "$exists" ]
	then
		echo "Site '$1' did not exist. Doing nothing." > /dev/stderr
		exit 0
	fi

	echo "Removing site '$1' from database." > /dev/stderr
	DB="$(echo "$DB" | grep -Gv '^'"$1"'	')"
	save='true'
}

# Find password, echo to stdout.
show() {
	entry="$(echo "$DB" | grep -G '^'"$1"'	')"
	if [ "$entry" ]
	then
		echo "$entry" | sed -r s/'^'"$1"'	'//
	else
		echo "Site '$1' has no entry." >> /dev/stderr
		exit 4
	fi
}

# Find password, copy to clipboard.
get() {
	entry="$(echo "$DB" | grep -G '^'"$1"'	')"
	if [ "$entry" ]
	then
		output="$(echo "$entry" | sed -r s/'^'"$1"'	'//)"
		echo "$output" | xclip -selection clipboard -loops 1
		echo "$output" | xclip -loops 1
	else
		echo "Site '$1' has no entry." >> /dev/stderr
		exit 4
	fi
}

if [ ! $2 ]
then
	usage $0
	exit 1
fi

case $1 in
add)
	add $2 $3;;
gen)
	add $2;;
del)
	del $2;;
show)
	show $2;;
get)
	get $2;;
*)
	usage $0
	exit 2;;
esac

if [ ! -d "$(dirname "${STORE_FILE}")" ]
then
	mkdir -p "$(dirname "${STORE_FILE}")"
fi

if [ "$save" ]
then
	echo "$DB" | $ENCRYPT_CMD > "${STORE_FILE}"
fi
