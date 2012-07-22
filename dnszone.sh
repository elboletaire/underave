#!/bin/bash

name_servers=("ns1.yourdomain.com" "ns2.yourdomain.com")
mail_servers=("mail.yourdomain.com")
mx_start_value=5
mx_increase_value=5
# comment this two lines to disable cache dns server
allow_transfer=("192.168.1.3" "192.168.1.6")
masters=("192.168.1.1")

dateformat="%y%m%d"
named_conf_file=/etc/bind/named.conf.local
zones_folder=/var/cache/bind
service_name=bind9


named_block () {
	cat <<EOZONE

zone "${domain}" in {
	type ${server_type};
	file "${domain}";
EOZONE

	if [[ $server_type = 'master' ]]; then
		echo "	allow-transfer {"
		for (( i = 0; i < ${#allow_transfer[@]}; i++ )); do
			echo "		${allow_transfer[$i]};"
		done
	else
		echo "	masters {"
		for (( i = 0; i < ${#masters[@]}; i++ )); do
			echo "		${masters[$i]};"
		done
	fi
		cat <<EOZONE
	};
};
EOZONE
}

zone_file () {
	cat <<EOZONE
\$ORIGIN ${domain}.
\$TTL	3h
@	IN	SOA	${name_servers[0]}.	elboletaire.underave.net. (
	`date +${dateformat}`00  ; se = serial number
	3h          ; ref = refresh
	15m         ; ret = update retry
	3w          ; ex = expiry
	3h          ; min = minimum
)

; DNS and MX
EOZONE

	for (( i = 0; i < ${#name_servers[@]}; i++ )); do
		echo "@			IN		NS		${name_servers[$i]}."
	done
	for (( i = 0; i < ${#mail_servers[@]}; i++ )); do
		echo "@			IN		MX	${mx_start_value}	${mail_servers[$i]}."
		mx_start_value=$(($mx_start_value+$mx_increase_value))
	done
	cat <<EOZONE

; Nodes in domain
@			IN		A		${domain_ip}.

; Aliases
www			IN		CNAME		@
mail			IN		CNAME		${mail_servers[0]}.

EOZONE
}

backup_named () {
	verbose "Backing up $named_conf_file to ${named_conf_file}.bak"
	if [ ! $backed_up ]; then
		# backup copy of named.conf file
		cp $named_conf_file $named_conf_file.bak
		backed_up=true
	fi
}

create_zone () {
	if [[ -f $zones_folder/$domain || $(config_block_exists) = true ]]; then
		echo "Zone exists. "
		if [ $force ]; then
			delete_zone
		else
			exit
		fi
	fi
	verbose "Writing zone file $domain in $zones_folder"
	zone_file | tee $zones_folder/$domain > /dev/null
	backup_named
	verbose "Writing zone block in $named_conf_file"
	named_block | tee -a $named_conf_file > /dev/null
}

config_block_exists () {
	cat $named_conf_file | awk -v s=${domain} 'BEGIN{RS=""; s="zone \""s"\""} $0~s{print $0"\n"}'
	if [ $? -eq 0 ]; then
		echo false
	else
		echo true
	fi
}

delete_zone () {
	if [[ ! $force && $(config_block_exists) = false ]]; then
		verbose "Config block in $named_conf_file does not exist. Terminating.." && exit
	fi
	backup_named
	verbose "Removing zone from $named_conf_file file"
	cat $named_conf_file | awk -v s=${domain} 'BEGIN{RS=""; s="zone \""s"\""} $0!~s{print $0"\n"}' > ${named_conf_file}.new
	# I don't know why can't I write directly to the file 
	mv ${named_conf_file}.new $named_conf_file
	# remove zone file from system only if in force mode
	[ $force ] && verbose "Removing zone $domain from $zones_folder" && rm $zones_folder/$domain
}

reload_service () {
	service $service_name reload
}

usage () {
	cat <<END_OF_USAGE
NAME
	$0 - Adds and removes DNS zones easily 

SYNOPSIS
	$0 [OPTION] [VALUE]
	$0 [OPTION] [OPTION] [VALUE] [VALUE] ...

DESCRIPTION
	If no params are specified, process will interactive

	-a|--add	Add a domain
	-f|--force	Force creation of domain (replaces existing files instead of skipping them)
	-m|--master	Create a zone in a master server
	-r|--remove	Remove a domain
	-s|--slave	Create a zone in a slave server
	-v|--verbose	Enable verbose
	-?|--help	Show this text

EXAMPLES
	Add a domain into a master server
		$0 -a -m domain.ext ip.to.your.host

	Add a domain into a slave server
		$0 -a -s domain.ext ip.to.your.host

	Add a domain into a master server forcing save (will replace existing files)
		$0 -a -m -f domain.ext ip.to.your.host

	Remove a domain
		$0 -r domain.ext

	Remove a domain with force (will delete the zone file too)
		$0 -r -f domain.ext

AUTHOR
	Òscar Casajuana <elboletaire@underave.net>
END_OF_USAGE
}

verbose () {
	if [ $verbose ]; then
		[ $# -eq 1 ] && echo $1 || echo $1 $2
	fi
}

## init ##

TEMP=`getopt -o armshfv -l add,remove,master,slave,force,verbose -n $0 -- "$@"`
if [ $? != 0 ] ; then verbose "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"
while true ; do
	case "$1" in
		-a|--add) 
			[ $action ] && echo "You cannot specify both remove and add actions" && exit
			action="add"
			shift
		;;
		-r|--remove)
			[ $action ] && echo "You cannot specify both remove and add actions" && exit
			action="remove"
			shift
		;;
		-m|--master)
			server_type="master"
			shift
		;;
		-s|--slave)
			server_type="slave"
			shift
		;;
		-f|--force)
			force=true
			shift
		;;
		-h|--help) usage && exit ;;
		-v|--verbose) verbose=true; shift; ;;
		--) shift ; break ;;
		*) echo "Internal error :\\" ; exit 1 ;;
	esac
done

if [[ ! $action  ]]; then
	usage && exit
fi

if [ $action = 'add' ]; then
	if [ ! $server_type ] || [ ! $# -eq 2 ]; then usage && exit; fi
	domain=$1
	domain_ip=$2
	create_zone
else
	[ ! $# -eq 1 ] && usage && exit
	domain=$1
	delete_zone
fi

reload_service

echo 'Done :)'

exit