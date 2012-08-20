#!/bin/bash

name_servers=("ns1.wonky.es" "ns2.wonky.es")
mail_servers=("mail.wonky.es")
mail_server_ips=("78.46.217.166")
mx_start_value=5
mx_increase_value=5
# comment this two lines to disable cache dns server
allow_transfer=("78.46.217.161" "176.9.142.14")
masters=("78.46.217.166")

dateformat="%y%m%d"
named_conf_file=/etc/bind/named.conf.local
zones_folder=/var/cache/bind
service_name=bind9


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
	-c|--cache|-s|--slave	Sets zone as a cache server
	-f|--force	Force creation of domain (replaces existing files instead of skipping them)
	-m|--master	Sets zone as a master server
	-r|--remove	Remove a domain
	-v|--verbose	Enable verbose
	-h|--help	Show this text

EXAMPLES
	Add a domain into a master server
		$0 -a domain.ext ip.to.your.host

	Add a domain into a cache server
		$0 -a -c domain.ext

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

named_block () {
	cat <<EOZONE

zone "${domain}" in {
	type ${server_type};
	file "${domain}";
EOZONE

	if [[ $server_type = 'master' && $allow_transfer ]]; then
		echo "	allow-transfer {"
		for (( i = 0; i < ${#allow_transfer[@]}; i++ )); do
			echo "		${allow_transfer[$i]};"
		done
	else
		if [[ $server_type = 'slave' && $masters ]]; then
			echo "	masters {"
			for (( i = 0; i < ${#masters[@]}; i++ )); do
				echo "		${masters[$i]};"
			done
		fi
	fi
	[[ $allow_transfer || $servers ]] && echo "	};"
	echo "};"
}

zone_file () {
	cat <<EOZONE
\$ORIGIN ${domain}.
\$TTL	3h
@	IN	SOA	${name_servers[0]}.	elboletaire.underave.net. (
	`date +${dateformat}`00    ; se = serial number
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
	for (( i = 0; i < ${#mail_server_ips[@]}; i++ )); do
		echo "@			IN		TXT		\"v=spf1 +a +mx +ip4:${mail_server_ips[$i]} -all\""
	done
	cat <<EOZONE

; Nodes in domain
@			IN		A		${domain_ip}

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
	if [ $server_type = 'master' ]; then
		verbose "Writing zone file $domain in $zones_folder"
		zone_file | tee $zones_folder/$domain > /dev/null
	fi
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
	mv ${named_conf_file}.new $named_conf_file
	# remove zone file from system only if in force mode
	if [[ $server_type = 'master' ]]; then
		[ $force ] && verbose "Removing zone file $domain from $zones_folder" && rm $zones_folder/$domain
	fi
}

reload_service () {
	service $service_name reload
}

verbose () {
	if [ $verbose ]; then
		[ $# -eq 1 ] && echo $1 || echo $1 $2
	fi
}

## init ##

TEMP=`getopt -o armchfv -l add,remove,master,cache,force,verbose -n $0 -- "$@"`
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
			[ $server_type ] && echo "You cannot specify both cache and master server types" && exit
			server_type="master"
			shift
		;;
		-c|-s|--cache|--slave)
			[ $server_type ] && echo "You cannot specify both cache and master server types" && exit
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

if [[ ! $server_type ]]; then
	server_type='master'
fi

if [ $action = 'add' ]; then
	if [[ ! $# -eq 2 && $server_type = 'master' ]]; then
		usage && exit
	else
		if [[ ! $# -eq 1 && $server_type = 'slave' ]]; then
			usage && exit
		fi
	fi
	domain=$1
	if [[ $server_type = 'master' ]]; then
		domain_ip=$2
	fi
	create_zone
else
	[ ! $# -eq 1 ] && usage && exit
	domain=$1
	delete_zone
fi

reload_service

echo 'Done :)'

exit
