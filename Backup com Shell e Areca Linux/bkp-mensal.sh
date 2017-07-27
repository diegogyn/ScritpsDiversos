#!/bin/bash

TAR="/bin/tar"
MT="/usr/bin/mt"
MOUNT="/bin/mount"
UMOUNT="/bin/umount"
SMBC="/usr/bin/smbclient"
DATE="/bin/date"
DATA=`$DATE +%d%m%Y`
LOG="/opt/logs/bkp-mensal-$DATA.log"

echo > $LOG 2>&1
echo " ** Iniciando Backup - `$DATE` " >> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
echo >> $LOG 2>&1

echo " ** Montando diretorios NFS - `$DATE` " >> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
#COLOCAR O IP:PASTA DO SERVIDOR
$MOUNT -t nfs 192.168.200.1:/mnt/backup/areca	/mnt/areca >> $LOG 2>&1
sleep 10
echo "============================================================" >> $LOG 2>&1
echo >> $LOG 2>&1

echo " ** Copiando Arquivos / Tamanho Total - `$DATE` " >> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
echo 								>> $LOG 2>&1
echo "============ INICIO ARECA `$DATE`: SIGA MENSAL ==========" >> $LOG 2>&1
/opt/areca/scripts/arecamensal.sh				>> $LOG 2>&1
echo "============ FIM ARECA `$DATE`: SIGA MENSAL =============" >> $LOG 2>&1
echo 								>> $LOG 2>&1
echo "============ INICIO ARECA `$DATE`: SIGA CONF ============"  >> $LOG 2>&1
/opt/areca/scripts/arecaconf.sh					>> $LOG 2>&1
echo "============ FIM ARECA `$DATE`:  SIGA CONF =============="  >> $LOG 2>&1
echo 								>> $LOG 2>&1
echo 								>> $LOG 2>&1

echo " ** Desmontando diretorios NFS - `$DATE` " >> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
cd /							>> $LOG 2>&1
$UMOUNT /mnt/areca					>> $LOG 2>&1
echo "============================================================" >> $LOG 2>&1
echo >> $LOG 2>&1
echo " ** Fim Backup - `$DATE` " >> $LOG 2>&1
