#!/bin/bash

#############
# FUNCIONES #
#############

function grupos {

	echo ""
	echo ""
	echo -n "       Escribe el dominio: "
	read dominio
	
	echo -n "       Escribe el nombre para el grupo: "
	read nombre

	gid=`cat ldap/gidNumber.txt`

	echo $nombre:$gid >> ldap/grupos.txt

	echo "dn: cn=$nombre,ou=Groups,dc=$dominio,dc=com
objectClass: posixGroup
cn: $nombre
gidNumber: $gid" > /tmp/add_content.ldif

 	ldapadd -x -D cn=admin,dc=$dominio,dc=com -W -f /tmp/add_content.ldif

	let gid=$gid+1
	echo $gid > ldap/gidNumber.txt

	echo ""
	echo ""
	echo "       Grupo creado"
	read -n 1 -s -r -p "       Pulsa una tecla para continuar.."
	./scriptldap.sh


}

function usuarios {

	echo ""
	echo ""
	echo -n "       ¿Quieres importar una lista de nombres? (s/n) "
	read sn

	case $sn in
		s)
			echo ""
			ls | grep *.txt | lolcat
			echo ""

			echo -n "       Escribe el directorio a la lista (.txt): "
			read path

			echo -n "       Escribe el dominio: "
			read dominio

			echo ""
			cat ldap/grupos.txt | lolcat 
			echo ""
	
			echo -n "       Escribe la ID del grupo donde estará: "
			read idgrupo

			echo "" > /tmp/add_content.ldif
	

			while IFS='' read -r name || [[ -n "$name" ]]; do

				uid=`cat ldap/uidNumber.txt`

				echo $name:$uid >> ldap/usuarios.txt
				cryptpass=`slappasswd -s $name -h {SSHA}`

				echo "dn: uid=$name,ou=People,dc=$dominio,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: $name
sn: $name
givenName: $name
cn: $name
displayName: $name
uidNumber: $uid
gidNumber: $idgrupo
userPassword: $cryptpass
gecos: ldap $name
loginShell: /bin/bash
homeDirectory: /home/$name

" >> /tmp/add_content.ldif

					let uid=$uid+1
					echo $uid > ldap/uidNumber.txt
	
			done < $path

			;;
		n)
			echo -n "       ¿Cuántos usuarios quieres crear? "
			read loop

			echo -n "       Escribe el dominio: "
			read dominio
	
			echo -n "       Escribe el nombre de usuario: "
			read nombre

			echo ""
			cat ldap/grupos.txt | lolcat 
			echo ""
	
			echo -n "       Escribe la ID del grupo donde estará: "
			read idgrupo

			echo "" > /tmp/add_content.ldif
	
			if [ "$loop" -eq "1" ]; then
				uid=`cat ldap/uidNumber.txt`

				echo $nombre:$uid >> ldap/usuarios.txt
				cryptpass=`slappasswd -s $nombre -h {SSHA}`

				echo "dn: uid=$nombre,ou=People,dc=$dominio,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: $nombre
sn: $nombre
givenName: $nombre
cn: $nombre
displayName: $nombre
uidNumber: $uid
gidNumber: $idgrupo
userPassword: $cryptpass
gecos: ldap $nombre
loginShell: /bin/bash
homeDirectory: /home/$nombre

" >> /tmp/add_content.ldif

				let uid=$uid+1
				echo $uid > ldap/uidNumber.txt

			else
				for i in `seq $loop`
				do
					uid=`cat ldap/uidNumber.txt`

					echo $nombre$i:$uid >> ldap/usuarios.txt

					echo "dn: uid=$nombre$i,ou=People,dc=$dominio,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: $nombre$i
sn: $nombre$i
givenName: $nombre$i
cn: $nombre$i
displayName: $nombre$i
uidNumber: $uid
gidNumber: $idgrupo
userPassword: $nombre$i
gecos: ldap $nombre$i
loginShell: /bin/bash
homeDirectory: /home/$nombre$i

" >> /tmp/add_content.ldif

					let uid=$uid+1
					echo $uid > ldap/uidNumber.txt
				done
			fi
			;;
	esac

	ldapadd -x -D cn=admin,dc=$dominio,dc=com -W -f /tmp/add_content.ldif

	
	echo ""
	echo ""
	echo "       Usuario(s) creados"
	read -n 1 -s -r -p "       Pulsa una tecla para continuar.."
	./scriptldap.sh

}

function verusuarios {
	
	clear
	echo ""
	echo "------------------------"
	echo "   Lista de Usuarios   "
	echo "------------------------"

	while IFS='' read -r line || [[ -n "$line" ]]; do
		OIFS="$IFS"
		IFS=':'
		read -a data <<< "${line}"
		IFS="$OIFS"

		echo "Display name: ${data[0]} - UID: ${data[1]}"
		
	done < ldap/usuarios.txt

	echo ""
	echo ""
	
	read -n 1 -s -r -p "       Pulsa una tecla para continuar.."
	./scriptldap.sh
}

function vergrupos {
	
	clear
	echo ""
	echo "------------------------"
	echo "   Lista de Grupos   "
	echo "------------------------"
	cat ldap/grupos.txt
	echo ""
	echo ""
	
	read -n 1 -s -r -p "       Pulsa una tecla para continuar.."
	./scriptldap.sh
}

function backups {
	
	
	if [ "$EUID" -ne 0 ]
	then 
		echo ""
		echo ""
		echo  "       Necesitas ser root.."
		echo ""
		exit
	else
		
		echo ""
		echo ""
		echo -n "       Importar/Exportar backup (i/e) "
		read ie

		case $ie in
			i)
				echo ""
				ls | grep .ldif | lolcat
				echo ""

				echo -n "       Escribe el directorio del backup (.ldif): "
				read path			
				
				/etc/init.d/slapd stop
				slapadd -c -l $path
				/etc/init.d/slapd start
				clear
				echo ""
				echo "       Backup importado con éxito!"
				;;
			e)	
				echo -n "       Escribe el nombre para el backup (.ldif): "
				read path	
				slapcat -l $path
				clear
				echo ""
				echo "       Backup exportado con éxito!"
				
				;;
			*)
				;;
		esac
	
		read -n 1 -s -r -p "       Pulsa una tecla para continuar.."
		./scriptldap.sh
	fi
}

function installldap {
	
	if [ "$EUID" -ne 0 ]
	then 
		echo ""
		echo ""
		echo  "       Necesitas ser root.."
		echo ""
		exit
	else
		echo ""
		echo ""
		echo -n "       ¿Estas seguro? (s/n) "
		read sn

		case $sn in
			s)
				apt-get purge slapd -y
				apt-get purge ldap-utils -y

				apt-get autoremove -y
	
				apt-get install slapd -y
				apt-get install ldap-utils -y

				dpkg-reconfigure slapd

				mkdir ldap
				rm ldap/grupos.txt
				touch ldap/grupos.txt

				rm ldap/usuarios.txt
				touch ldap/usuarios.txt

				echo 5000 > ldap/gidNumber.txt
				echo 10000 > ldap/uidNumber.txt


				echo ""
				echo ""
				echo -n "       Escribe el dominio: "
				read dominio

				echo "dn: ou=People,dc=$dominio,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=$dominio,dc=com
objectClass: organizationalUnit
ou: Groups" > /tmp/add_content.ldif

				ldapadd -x -D cn=admin,dc=$dominio,dc=com -W -f /tmp/add_content.ldif

				clear
				echo ""
				echo ""
				echo "       LDAP Instalado con exito!"
				read -n 1 -s -r -p "       Pulsa una tecla para continuar.."
				./scriptldap.sh
				;;
			n)
				./scriptldap.sh
				;;
		esac
	fi	
}

####################
# FIN DE FUNCIONES #
####################



clear
echo ""
echo ""
echo "                      Menú"
echo "       -------------------------------------- "
echo "          0- Reinstalar LDAP                  "
echo "          1- Crear grupo                      "
echo "          2- Crear usuarios                   "
echo "          3- Ver grupos creados               "
echo "          4- Ver usuarios creados             "
echo "          5- Backups                          "
echo "          6- --placeholder--                  "
echo "          7- Exit                             "
echo "       -------------------------------------- "

echo -n "       Opcion: "
read resp

case $resp in
	0)
		installldap
		;;
	1)
		grupos
		;;
	2)
		usuarios
		;;
	3)
		vergrupos
		;;
	4)
		verusuarios
		;;
	5)
		backups
		;;
	6)
		;;
	*)
		exit
		;;
esac
