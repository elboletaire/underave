#!/bin/bash

# TODO: afegir usuari mysql i crear base de dades buida donant permisos a l'usuari creat.
# TODO: assegurar-se que l'usuari pot accedir al phpmyadmin sense rebre errors 
# TODO: plantejar-se si afegir una redirecció o un subdomini que porti al phpmyadmin

if [ $(id -u) != "0" ]; then
	echo "You must be root"
	exit 1
fi

# Default variables
www_root=/var/www
usergroup=www-data

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
	-g	Change user group
	-h	Specify homedir (default's to \$www_root/\$username)
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

generate_username () {
	echo $fqdn | sed 's/\([[:alnum:]][[:alnum:]]*\)\.\([[:graph:]][[:graph:]]*\)/\1/g';
}

init () {
	case $action in

		"add")
			create_user
			create_data
			create_virtual_host
			htpasswd_add
			create_awstats_file
			set_permissions
			reload_daemons
			create_cron
		;;

		"remove")
			echo "Are you sure that you wanna remove user $username and its dir $homedir?? This really can't be undone!!!! [yes|no]"
			read yesno
			while [ $yesno != "no" ] && [ $yesno != "yes" ]; do
				echo "Please, write \"yes\" or \"no\""
				read yesno
			done
			if [ $yesno = "yes" ]; then
				remove_user
				remove_data
				remove_virtualhost
				reload_daemons
			else
				verbose "You're rethinking it, huh? Well done"
				exit 1
			fi
		;;
	esac

	echo "Done :)"
}

create_data () {
	if [ -d $homedir ] && [ ! $force ]; then
		verbose "Homedir $homedir exists, skipping.."
		return
	fi
	# folders and aliases..
	create_folders
	verbose "Symlinking www to public_html..."
	ln -s $homedir/www $homedir/public_html
	# "it works" file
	verbose "Creating index.html file..."
	echo '<!DOCTYPE html><html><body><h1>It works, bitches</h1></body></html>' > $homedir/www/index.html
	verbose "Creating mysql schema..."
	mysql -e "CREATE SCHEMA IF NOT EXISTS $username;"
}

create_folders () {
	verbose "Creating folders..."
	mkdir -m 1750 -p $homedir/www
	mkdir -m 1750 -p $homedir/tmp/awstats/conf
	mkdir -m 1750 -p $homedir/tmp/awstats/lib
	mkdir -m 1750 -p $homedir/tmp/log
}

create_awstats_file () {
	verbose "Creating awstats configuration"
	echo "# BASIC AWSTATS CONFIGURATION
Include \"/etc/awstats/awstats.conf.local\"

LogFile=\"$homedir/tmp/log/$username-access.log\"

SiteDomain=\"www.$fqdn\"

# Example: \"www.myserver.com localhost 127.0.0.1 REGEX[mydomain\.(net|org)\$]\"
HostAliases=\"localhost 127.0.0.1 $fqdn www.$fqdn\"

DirData=\"$homedir/tmp/awstats/lib/\"

AllowAccessFromWebToFollowingAuthenticatedUsers=\"elboletaire $username\"" > $homedir/tmp/awstats/conf/awstats.$fqdn.conf
}

create_user () {
	if [ $(check_user_exists) = true ]; then
		verbose "User $username exists, skipping.."
		return
	fi
	verbose "Creating system user..."
	useradd $username -p $password -d $homedir -s /bin/bash
	verbose "Creating mysql user..."
	mysql -e "GRANT ALL PRIVILEGES ON $username.* TO $username@'localhost' IDENTIFIED BY '$password';"
	mysql -e "GRANT ALL PRIVILEGES ON $username.* TO $username@'192.168.0.6' IDENTIFIED BY '$password';"
	mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE, LOCK TABLES ON phpmyadmin.* TO $username@'192.168.0.6';"
}

check_user_exists () {
	egrep -i "^$username" /etc/passwd > /dev/null
	[ $? -eq 0 ] && echo true || echo false
}

remove_user () {
	verbose "Removing system user.."
	[ $force ] && userdel -f $username || userdel $username
	verbose "Removing mysql user.."
	mysql -e "DROP USER $username@'localhost';"
	mysql -e "DROP USER $username@'192.168.0.6';"
}

remove_data () {
	# remove schema..
	[ $force ] && mysql -e "DROP SCHEMA $username;"
	# remove folders..
	if [ ! $force ]; then
		[ $verbose ] && rm -v $homedir || rm $homedir
	else
		[ $verbose ] && rm -rv $homedir || rm -fr $homedir
	fi
}

# set permissions
set_permissions () {
	verbose "Setting user permissions..."
	chown -R $username:$usergroup $homedir
	chmod -R 1775 $homedir/www
}

create_virtual_host () {
	verbose "Creating apache virtual host..."
	echo "
<VirtualHost *:80>
	ServerAdmin elboletaire@underave.net
	ServerName panel.$fqdn

	DocumentRoot /var/www/panel/

	<Directory /var/www/panel/>
		Options FollowSymLinks
		AllowOverride all

		RewriteEngine On
		RewriteRule ^stats\/?$ /awstats/awstats.pl?configdir=$homedir/tmp/awstats/conf/&config=$fqdn [R=301,L]
	</Directory>

	 <Location />
		AuthType Basic
		AuthName \"$fqdn control panel\"
		AuthUserFile $homedir/.htpasswd
		Require valid-user
		SetEnv AWSTATS_ENABLE_CONFIG_DIR 1
	</Location>
</VirtualHost>
<VirtualHost *:80>
	ServerAdmin elboletaire@underave.net
	ServerName $fqdn
	ServerAlias www.$fqdn

	DocumentRoot $homedir/www/

	<Directory $homedir/www/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		Order allow,deny
		Allow from all
	</Directory>

	ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
	<Directory \"/usr/lib/cgi-bin\">
		AllowOverride None
		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
		Order allow,deny
		Allow from all
	</Directory>

	ErrorLog $homedir/tmp/log/$username-error.log

	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	CustomLog $homedir/tmp/log/$username-access.log combined
</VirtualHost>" > /etc/apache2/sites-available/$fqdn

	a2ensite $fqdn
}

create_cron () {
	verbose "Creating cron..."
	echo "*/30 * * * * /usr/local/bin/awstats_updateall.pl -configdir=$homedir/tmp/awstats/conf/ -awstatsprog=/usr/lib/cgi-bin/awstats.pl now" | crontab -u $username -
}

remove_virtualhost () {
	a2dissite $fqdn
	rm -v /etc/apache2/sites-available/$fqdn
}

htpasswd_add () {
	if [ ! -f $homedir/.htpasswd ]; then
		htpasswd -b -c $homedir/.htpasswd $username $password
	else
		htpasswd -b $homedir/.htpasswd $username $password
	fi
}

reload_daemons () {
	service apache2 reload
}

# main

while getopts ":a:r:h::g::w::p::u:fvi?" opt; do
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
		g) usergroup=$OPTARG; ;;
		h) homedir=$OPTARG ;;
		i) interactive=true; ;;
		p) password=$OPTARG ;;
		u) username=$OPTARG ;;
		v) verbose=true; ;;
		w) www_root=$OPTARG; ;;
		?) usage && exit; ;;
		:) echo "You must specify an argument for -$OPTARG option" && exit ;;
	esac
done

set_vars
init
