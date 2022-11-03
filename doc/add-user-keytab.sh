#!/bin/bash

set -e

login="${1:?Domain login is requred}"
user="${2:-cntlm}"

if ! ktutil=$(type -p ktutil 2>/dev/null) ; then
    echo "Cannot find ktutil tool, krb5 tools package is installed ?" >/dev/stderr
    exit 1
fi

# * The KRB5_CLIENT_KTNAME environment variable.
# * The default_client_keytab_name profile variable in [libdefaults].
# * The hardcoded default, DEFCKTNAME.

libfile=$(ldd "$ktutil" | awk '/libkrb5.so./ { print $3; q; }')
mask=$(strings "$libfile" | grep '%{euid}/client.keytab')

if [ -z "$mask" ] ; then
    echo "Cannot find libkrb5.so, krb5 is installed ?" >/dev/stderr
    exit 1
elif ! [[ "$mask" = FILE:* ]] ; then
    echo "Unsupported keytab storage '$mask' !" >/dev/stderr
    exit 1
fi

mask=${mask#FILE:}

euid=$(id -u "$user")
egid=$(id -g "$user")

keytab=$(sed "s/%{euid}/$euid/" <<<$mask)

principal="$login"
if ! [[ "$principal" = *@* ]] ; then

    default_realm=''
    for conf in /etc/krb5.conf /etc/krb5.conf.d/*.conf ; do
        [ -f "$conf" ] || continue
        default_realm=$(awk -re '/^\s+default_realm/{ print $3; }' "$conf" | tail -n1)
    done

    if [ -z "$default_realm" ] ; then
        echo "Cannot find default realm for your configuration, please use full principal like $login@EXAMPLE.ORG !" >/dev/stderr
        exit 1
    fi
    principal="$login@$default_realm"
fi

IFS= read -s -p "Enter password for $principal : " pass

echo

configs_dir=$(dirname "$keytab")
install -d -m 0700 -o "$user" -g "$egid" "$configs_dir"

rm -f "$keytab"

echo "*** Create '$keytab' for user $user using principal $principal"

"$ktutil"  <<EOT
addent -password -p $principal -k 1 -f
$pass
list
wkt $keytab
q
EOT

chmod 0600 "$keytab"
chown "$user:$egid" "$keytab"

exit 0
