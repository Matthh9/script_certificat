#!/bin/bash

#script de transfert et d'application des certificats pour les machines encodeur TDR
# Auteur : Matthieu DA SILVA
# DATE : 29/06/2022

#
# ce script permet d'installer automatiquement les certificats sur l'ensemble des encodeurs IPTV
# lors du lancement il va regarder l'ensemble des fichiers .key et se basser sur le nom pour lancer l'update des certificat
# le compte elemental permettant de faire les sauvegardes et pouvant se connecter sans mdp (échange de clé ssh) est utilisé pour accèder à la machine distante
#


chemin_certificat="/root/outil_certificat/certificat_a_installer"
chemin_certificat_traite="/root/outil_certificat/certificat_installe"
user="ssh user"

for fichier_key in $chemin_certificat/nms*.key
do
	nom_serveur=$(echo $fichier_key | awk -F/ '{print $NF}' | cut -d "." -f 1)
	nom_certificat=$(basename $fichier_key .key | awk -F/ '{print $NF}')
	
	echo "____________________________________________"
	echo $nom_serveur
	echo $nom_certificat

	#vérifier s'il y a le certificat dans le dossier .pem ou .crt
	if [ -f $chemin_certificat'/'$nom_certificat.crt ] || [ -f $chemin_certificat'/'$nom_certificat.pem ]; then

		if ! [ -f $chemin_certificat'/'$nom_certificat.crt ] || [ -f $chemin_certificat'/'$nom_certificat.pem ]; then
			rename $nom_certificat.pem $nom_certificat.crt $chemin_certificat/$nom_certificat.pem	
		fi
		
		#on renomme les fichiers de l'encodeur pour respecter le fichier de conf httpd 
		rename $nom_certificat server $chemin_certificat/$nom_certificat*

		#renommage de l'ancien certificat avec l'année pour le mettre en BU
		ssh $user@$nom_serveur 'annee=`/usr/bin/date +%Y` && sudo rename server server-$annee /etc/httpd/conf/server*'

		#copie de tous les fichiers pour le certificat en question vers le serveur
		/usr/bin/scp $chemin_certificat'/'server* $user@$nom_serveur:/tmp/
		#déplacer avec sudo au bon endroit pour régler des pb de droits sur certain encodeur
		ssh $user@$nom_serveur 'sudo mv /tmp/server.* /etc/httpd/conf/'		

		#on rechange le nom et on deplace les fichiers traités dans un autre dossier s'il y a besoin d'une intervention manuelle
		rename server $nom_certificat $chemin_certificat/server*
		mv $chemin_certificat'/'$nom_certificat* $chemin_certificat_traite


		###application de la conf httpd et du nouveau certiifcat en faisant un reboot du service httpd
		ssh $user@$nom_serveur 'sudo systemctl restart httpd'
		resultat=$(ssh $user@$nom_serveur 'sudo systemctl status httpd | grep "active (running)"')
		echo $resultat


		###curl pour checker la date de fin de validité du certificat
		expiration_date=$(curl https://$nom_certificat -vI --stderr - | grep "expire date" | cut -d":" -f 2-);
        expiration_date=$(date -d "$expiration_date" +'%Y%m%d');

        today=$(date +'%Y%m%d');

        delta=$(( ($(date --date=$expiration_date +%s) - $(date --date=$today +%s) )/(60*60*24) ))
        
        if [ $delta -gt 300 ] && [ $delta -lt 367 ];
        then
            echo "Installation OK"
        else
            echo "Installation NOK"
        fi


	else
		echo "erreur pas de certificat"
	fi
done
