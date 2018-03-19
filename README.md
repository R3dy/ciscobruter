Ciscobruter.rb
==============
Brute force Cisco SSL VPN's that don't use 2-factor authentication


Install:
--------
Simply clone this repo and run

	$ bundle install


Help:
-----
	$ ./ciscobruter.rb -h
	ciscobruter.rb VERSION: 1.0.0 - UPDATED: 01/20/2016

	    -u, --username   [Username]      	Username to guess passwords against
	    -p, --password   [Password]      	Password to try with username
	    -U, --user-file  [File Path]     	File containing list of usernames
	    -P, --pass-file  [File Path]     	File containing list of passwords
	    -t, --target     [URL]           	Target VPN server example: https://vpn.target.com
	    -l, --login-path [Login Path]    	Path to login page.  Default: /+webvpn+/index.html
	    -g, --group      [Group Name]    	Group name for VPN.  Default: No Group   
	    -v, --verbose                    	Enables verbose output


Example:
--------
	$ ./ciscobruter.rb -t https://vpn.targetserver.com -U usernames.txt -p "Winter2015!"
