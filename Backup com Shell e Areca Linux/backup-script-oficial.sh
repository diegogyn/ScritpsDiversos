#!/bin/bash

#ARQUIVO MODELO PARA MONTAGEM

TAR="/bin/tar"
MT="/usr/bin/mt"
MOUNT="/bin/mount"
UMOUNT="/bin/umount"
SMBC="/usr/bin/smbclient"
DATE="/bin/date"
DATA=`$DATE +%d%m%Y`
LOG="/opt/logs/bkp-$DATA.log"
SQLDIR="/mnt/sql"

echo > $LOG 2>&1
echo " ** Iniciando Backup - `$DATE` " >> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
echo >> $LOG 2>&1

echo " ** COPIANDO BANCO DE DADOS - `$DATE` " >> $LOG 2>&1
echo >> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
cd $SQLDIR >> $LOG 2>&1
# COPIANDO ARQUIVO DO WINDOWS
$SMBC //server-sql/d$ -I 192.168.200.1 -U 'usuario'%'senha' -c "prompt ; cd sql_back ; mget DADOSADV.bkp" >> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
echo >> $LOG 2>&1

echo " ** Montando diretorios NFS - `$DATE` " >> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
$MOUNT -t nfs 192.168.200.1:/DataVolume/bkp	/mnt/bkp >> $LOG 2>&1
sleep 10
echo "============================================================" >> $LOG 2>&1
echo >> $LOG 2>&1

echo " ** Copiando Arquivos / Tamanho Total - `$DATE` " >> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
mkdir /mnt/bkp/arquivos/$DATA/					>> $LOG 2>&1
cd /mnt/bkp/arquivos/$DATA/				      	>> $LOG 2>&1
cp -Rf /mnt/sql/		/mnt/bkp/arquivos/$DATA/ 	>> $LOG 2>&1
cp -Rf /dados2/			/mnt/bkp/arquivos/$DATA/ 	>> $LOG 2>&1
cp -Rf /dados/			/mnt/bkp/arquivos/$DATA/ 	>> $LOG 2>&1
du -sh /mnt/bkp/arquivos/$DATA/					>> $LOG 2>&1
echo >> $LOG 2>&1

echo " ** Desmontando diretorios NFS - `$DATE` " >> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
cd /							>> $LOG 2>&1
$UMOUNT /mnt/bkp					>> $LOG 2>&1
rm -Rf /mnt/sql/DADOSADV.bkp				>> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
echo >> $LOG 2>&1
echo " ** Fim Backup - `$DATE` " >> $LOG 2>&1
