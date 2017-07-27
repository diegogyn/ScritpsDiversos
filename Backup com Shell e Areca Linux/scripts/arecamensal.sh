# SCRIPT DE BACKUP ATUALIZADO DIA: 01/08/2012

# Full backup
# Target Group : "MICROSIGA"
# Target : "MICROSIGA MENSAL"

# BACKUP MENSAL COMPLETO
# ESSE SCRIPT DEVE SER RODADO TODO DIA 1.

"/opt/areca/bin/areca_cl.sh" backup -f -c -config "/opt/areca/workgroup/MICROSIGA/1021988763.bcfg" -title "COMPLETO MENSAL"

