# SCRIPT DE BACKUP ATUALIZADO DIA: 01/08/2012

# Full backup
# Target Group : "MICROSIGA"
# Target : "MICROSIGA DIARIO"

# BACKUP DO BANCO DE DADOS
# ESTE SCRIPT DEVE SER RODADO TODO DIA!

"/opt/areca/bin/areca_cl.sh" backup -f -c -config "/opt/areca/workgroup/MICROSIGA/140751719.bcfg" -title "MICROSIGA DIARIO"

"/opt/areca/bin/areca_cl.sh" merge -c -config "/opt/areca/workgroup/MICROSIGA/140751719.bcfg" -delay 20
