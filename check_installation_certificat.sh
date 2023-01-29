#!/bin/bash

#script de transfert et d'application des certificats pour les machines encodeur TDR
# Auteur : Matthieu DA SILVA
# DATE : 29/06/2022

#
# ce script permet d'installer automatiquement les certificats sur l'ensemble des encodeurs IPTV
# lors du lancement il va regarder l'ensemble des fichiers .key et se basser sur le nom pour lancer l'update des certificat
# le compte elemental permettant de faire les sauvegardes et pouvant se connecter sans mdp (échange de clé ssh) est utilisé pour accèder à la machine distante
#


chemin_certificat="/root/outil_certificat/certificat_installe"
chemin_certificat_traite="/root/outil_certificat/certificat_installe"

for fichier_key in $chemin_certificat/*.key
do
	nom_serveur=$(echo $fichier_key | awk -F/ '{print $NF}' | cut -d "." -f 1)
	nom_certificat=$(basename $fichier_key .key | awk -F/ '{print $NF}')
	
	echo "____________________________________________"
	echo $nom_serveur
	echo $nom_certificat

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

done
