# SCRIPT DE BACKUP ATUALIZADO DIA: 01/08/2012

# Full backup
# Target Group : "MICROSIGA"
# Target : "MICROSIGA CONF"

# BACKUP CONFIGURACOES DO SERVIDOR
# ESTE SCRIPT DEVE SER RODADO TODO DIA!

"/opt/areca/bin/areca_cl.sh" backup -f -c -config "/opt/areca/workgroup/MICROSIGA/405123958.bcfg" -title "CONF MICROSIGA"

"/opt/areca/bin/areca_cl.sh" merge -c -config "/opt/areca/workgroup/MICROSIGA/405123958.bcfg" -delay 03


