#!/bin/bash                                                                      #
# CITRA IT - EXCELENCIA EM TI                                                    #
# Script para backup a quente do Nextcloud                                       #
# @Author: luciano@citrait.com.br                                                #
# @Data: 15/06/2023                                                              #
# @Usage: agendar a execução deste script no crontab do root ou www-data.        # 
##################################################################################

# data/hora da execucao do script
TIMESTAMP=$(date +%F-%H-%S)

# arquivo log de saida
LOGFILE=/var/log/nextcloud_backup.log

# funcao para mostrar uma entrada de log na tela e no arquivo de log
# com prefixo de data-hora.
function log(){
    echo "$(TZ=America/Sao_Paulo date -Iseconds) $1" | tee -a $LOGFILE
}

# funcao para mostrar uma entrada de log na tela e no arquivo de log
# sem prefixo de data-hora.
function rawlog(){
  echo "$1" | tee -a $LOGFILE
}


### ROTINA PRINCIPAL ###
log "----------------==========================-----------------"
log "              SCRIPT DE BACKUP NEXTCLOUD                   "
log "----------------==========================-----------------"
log "Iniciando novo backup a quente do Nextcloud"

# Realizando o dump do banco de dados
log "Realizando dump do banco de dados"
su - postgres -c "pg_dump -Fc -f /tmp/database-${TIMESTAMP}.fc  -C -c nextcloud_db" | tee -a $LOGFILE

log "Movendo o dump do banco para a pasta de backup..."
mv /tmp/database-${TIMESTAMP}.fc /backup/nextcloud/database-${TIMESTAMP}.fc
DBDUMPSIZE=$(du -sh /backup/nextcloud/database-${TIMESTAMP}.fc)
log "Tamanho do banco de dados (dump): ${DBDUMPSIZE}"

# Realizando a copia dos arquivos Nextcloud
log "Realizando copia do Nextcloud..."
log "---- ESTATISTICAS COPIA NEXTCLOUD ----"
rsync -az --stats -h /var/www/nextcloud/ /backup/nextcloud/var/www/nextcloud | tee -a $LOGFILE

# Realizando a copia dos Dados
log "Realizando copia dos Dados..."
log "---- ESTATISTICAS COPIA DADOS (USER FILES) ----"
rsync -az --stats -h /mnt/ncdata/ /backup/nextcloud/mnt/ncdata | tee -a $LOGFILE

log "Finalizado o backup do nextcloud"
log  "Tamanho consumido pelo backup: $(du -sh /backup/nextcloud)"

# Enviando email com log anexo
if [ -f /scripts/02_send_email.py ]; then
    /scripts/send_email.py
fi

