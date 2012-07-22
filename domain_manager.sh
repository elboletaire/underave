#!/bin/bash

# Default variables
www_root=/var/www

usage () {
	cat <<END_OF_USAGE
NAME
	$0 - Adds and removes domains easily

SYNOPSIS
	$0
	$0 [OPTION] [VALUE] ...

DESCRIPTION
	If no params are specified, process will interactive

	-a	Add a domain
	-f	Force creation of domain (replaces existing files instead of skipping them)
	-h	Specify homedir
	-i	Interactive mode. It also enables -v
	-r	Remove a domain
	-u	Specify username (otherwise it will bw prompt)
	-v	Enable verbose
	-w	Change www root folder (default's to /var/www)
	-?	Show this text

EXAMPLES
	Start process interactively:
		$0 -i

	Add a domain
		$0 -a domain.ext

	Add a domain with different default user
		$0 -a domain.ext -u username

	Add a domain with different default user and homedir
		$0 -a domain.ext -u username -h /home/username

	Remove a domain
		$0 -r domain.ext

	Remove a domain with different default user
		$0 -r domain.ext -u username

	And so on...

AUTHOR
	Òscar Casajuana <elboletaire@underave.net>
END_OF_USAGE
}

set_vars () {
	if [ $interactive ]; then
		if [ ! $action ]; then
			echo -n "Enter action to do [add|remove]:"
			read action
			while [ $action != "add" ] && [ $action != "remove" ]; do
				echo "Please, enter \"add\" or \"remove\""
				read action
			done
		fi
		if [ ! $fqdn ]; then
			echo -n "Enter fully qualified domain name (without www): "
			read fqdn
		fi
		if [ ! $username ]; then
			echo $(generate_username)
			username=$(generate_username)
			echo -n "Enter username [$username]: "
			read uname
			if [ $uname ]; then username=$uname; fi
		fi
		if [ ! $homedir ]; then
			homedir=$www_root/$username
			echo -n "Enter home dir [$homedir]: "
			read $hd
			if [ $hd ]; then homedir=$hd; fi
		fi
	else
		if [ ! $action ] || [ ! $fqdn ]; then usage;exit 1; fi
		if [ ! $username ]; then username=$(generate_username); fi
		if [ ! $homedir ]; then homedir=$www_root/$username; fi
	fi
	# set user password
	if [ $action == 'add' ] && [ ! $password ]; then
		while [ $password != $password_verify ]; do
			read -s -p "User password: " password; echo ""
			read -s -p "Again (verification): " password_verify; echo ""
		done
	fi

	# debug
	# exit
}

verbose () {
	if [ $verbose ] || [ $interactive ]; then
		echo $1
	fi
}

debug () {
	echo "Action: $action"
	echo "FQDN: $fqdn"
	echo "Username: $username"
	echo "Homedir: $homedir"
	echo "Password: $password"
	echo "www_root: $www_root"
	echo -n "Verbose: "; [ $verbose ] && echo 'yes' || echo 'no'
	echo -n "Interactive: "; [ $interactive ] && echo 'yes' || echo 'no'
	echo -n "Force: "; [ $force ] && echo 'yes' || echo 'no'
}

generate_username () {
	echo $fqdn | sed 's/\([[:alnum:]][[:alnum:]]*\)\.\([[:graph:]][[:graph:]]*\)/\1/g';
}

init () {
	case $action in

		"add")
			verbose "+ Creating user.."
			create_user
			verbose "++ Creating folders.."
			create_folders
			verbose "+++ Creating virtual host.."
			create_virtual_host
			verbose "++++ Setting permissions"
			set_permissions
			verbose "+++++ Reloading daemons"
			reload_daemons
		;;

		"remove")
			echo "Are you sure that you wanna remove $username?? This really can't be undone!!!! [yes|no]"
			read yesno
			while [ $yesno != "no" ] && [ $yesno != "yes" ]; do
				echo "Please, write \"yes\" or \"no\""
				read yesno
			done
			if [ $yesno = "yes" ]; then
				verbose "+ Removing user.."
				remove_user
				verbose "++ Removing folders and contents.."
				remove_folders
				verbose "+++ Removing virtual host.."
				remove_virtualhost
				verbose "++++ Reloading daemons"
				reload_daemons
			else
				verbose "You're rethinking it, huh? Well done"
				exit 1
			fi
		;;
	esac

	echo "Done :)"
}

create_folders () {

	if [ -d $homedir ] && [ ! $force ]; then
		verbose "Homedir $homedir exists, skipping.."
		return
	fi

	# folders and aliases..
	mkdir -m 1750 -p $homedir/www
	ln -s $homedir/www $homedir/public_html
	echo '<!DOCTYPE html><html><body><h1>It works, bitches</h1></body></html>' > $homedir/www/index.html
}

remove_folders () {
	rm -frv $homedir
}

create_user () {
	if [ $(check_user_exists) = true ]; then
		verbose "User $username exists, skipping.."
		return
	fi
	useradd $username -p $password -d $homedir
}

check_user_exists () {
	egrep -i "^$username" /etc/passwd > /dev/null
	[ $? -eq 0 ] && echo true || echo false
}

remove_user () {
	if [ $(check_user_exists) = true ]; then
		verbose "User exists. Skipping.."
	fi
	[ $force ] && userdel -fr $username || userdel $username
}

# set permissions
set_permissions () {
	chown -R $username:clients $homedir
	chmod -R 1755 $homedir/www
}

create_virtual_host () {
	echo "<VirtualHost *:80>
		ServerAdmin elboletaire@underave.net
		ServerName $fqdn
		ServerAlias www.$fqdn

		DocumentRoot $homedir/www/
		<Directory />
				Options FollowSymLinks
				AllowOverride none
		</Directory>
		<Directory $homedir/www/>
				Options Indexes FollowSymLinks MultiViews
				AllowOverride All
				Order allow,deny
				Allow from all

				RewriteEngine On

				RewriteCond %{HTTP_HOST} ^(www\.)?(.+)$ [NC]
				RewriteRule ^stats\/?$ /awstats/awstats.pl?config=%2 [R=301,L]
		</Directory>

		<Location /awstats>
				AuthType Basic
				AuthName \"awstats\"
				AuthUserFile $homedir/.htpasswd
				Require valid-user
		</Location>

		ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
		<Directory \"/usr/lib/cgi-bin\">
				AllowOverride None
				Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
				Order allow,deny
				Allow from all
		</Directory>

		ErrorLog ${APACHE_LOG_DIR}/$username-error.log

		# Possible values include: debug, info, notice, warn, error, crit,
		# alert, emerg.
		LogLevel warn

		CustomLog ${APACHE_LOG_DIR}/$username-access.log combined
</VirtualHost>" > /etc/apache2/sites-available/$fqdn
	verbose $(a2ensite $fqdn)
}

remove_virtualhost () {
	verbose $(a2dissite $fqdn)
	verbose $(rm -frv /etc/apache2/sites-available/$fqdn)
}

reload_daemons () {
	service apache2 reload
}

# main

while getopts ":a:r:h::w::p::u:fvi?" opt; do
	case $opt in
		a)	if [ $action ]; then echo "You can't specify both remove (-r) and add (-a) options" && exit; fi
			if [ $OPTARG ]; then fqdn=$OPTARG; fi
			action="add"
		;;
		r)	if [ $action ]; then echo "You can't specify both remove (-r) and add (-a) options" && exit; fi
			if [ $OPTARG ]; then fqdn=$OPTARG; fi
			action="remove"
		;;
		f) force=true; ;;
		h) homedir=$OPTARG ;;
		i) interactive=true; ;;
		p) password=$OPTARG ;;
		u) username=$OPTARG ;;
		v) verbose=true ;;
		w) www_root=$OPTARG ;;
		?) usage && exit; ;;
		:) echo "You must specify an argument for -$OPTARG option" && exit ;;
	esac
done

set_vars
init
