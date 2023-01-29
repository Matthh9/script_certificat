#!/usr/bin/env bash
#
# Auteur : Matthieu DA SILVA
# Date : juin 2022
#

echo "Début génération de la clé"

openssl genrsa 2048 >  $1.key

echo "fin de génération de la clé"
echo "____________________________________________________________________________________________________"
echo "Début de génération du csr"

echo openssl req -out $1.csr -key $1.key -sha256 -new -subj "/C=FR/ST=Ile-de-France/L=lieu/O=entreprise/CN=$1"
openssl req -out $1.csr -key $1.key -sha256 -new -subj "/C=FR/ST=Ile-de-France/L=lieu/O=entreprise/CN=$1"

echo "Fin de génération du csr"

