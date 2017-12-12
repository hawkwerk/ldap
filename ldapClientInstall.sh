#!/bin/bash
if [ "$EUID" -ne 0 ]
then
	echo ""
	echo "   Necesitas ser root.."
	echo ""
	exit
else
	apt-get purge libnss-ldap -y
	apt-get purge libpam-ldap -y
	
	apt-get autoremove -y

	apt-get install libnss-ldap libpam-ldap -y

	echo "# /etc/nsswitch.conf
passwd:         compat ldap
group:          compat ldap
shadow:         compat ldap

hosts:          files mdns4_minimal [NOTFOUND=return] dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       ldap" > /etc/nsswitch.conf

echo "session required        pam_mkhomedir.so" >> /etc/pam.d/common-session

echo "# /etc/pam.d/common-session
password	[success=2 default=ignore]	pam_unix.so obscure sha512
password	[success=1 user_unknown=ignore default=die]	pam_ldap.so try_first_pass

password        requisite			pam_deny.so

password	required			pam_permit.so

password	optional	pam_gnome_keyring.so" > /etc/pam.d/common-password

clear
echo ""
echo "     LDAP Instalado con éxito!"
echo -n " Quieres reiniciar tu equito? (s/n) "
read rb

case rb in 
	s)
		reboot
		;;
	*)
		echo ""
		;;
esac

fi
