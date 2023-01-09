#!/bin/bash
echo -e "==> Backup SisBol\n"

# variaveis
dir_boletim="/var/www/band/boletim"
senhaBD="MINHA SENHA AQUI"


carregaDados() {
  DATA=$(date +%Y-%m-%d)
  DIRBKP=/backup   #diretorio de destino do backup
  ARQUIVO_TAR_GZ="$DIRBKP/$DATA-bkp-sisbol.tar.gz"
  DIAS_BKP=+5  #numero de dias em que sera deletado o arquivo de backup
  DATABASE="cta" #database do sistema
  LOG="$DIRBKP/log.$DATA-bkp-sisbol"
  DESTINO_REMOTO="<USUARIO>@<IP_SERVIDOR_BKP>:/disco01/sisbol/"
  ARQUIVOS="/root/bkp_sisbol.sh
  "
  #cria dir bkp, se nao existir:
  if [ ! -d "$DIRBKP" ]; then mkdir -p $DIRBKP; fi
  if [ ! -d "$DIRBKP/pdf" ]; then mkdir -p $DIRBKP/pdf; fi
  if [ ! -d "$DIRBKP/database" ]; then mkdir -p $DIRBKP/database; fi
  if [ ! -d "$DIRBKP/config" ]; then mkdir -p $DIRBKP/config; fi

  echo "----------------------------------------" >> $LOG
  echo "Data de inicio: $(date +%d%H%M%b%y)" >> $LOG
}

geraBackup() {
  # backup BD
  echo -ne "--> Gerando Backup do Banco de Dados..." >> $LOG
  /usr/bin/mysqldump -u root -p$senhaBD cta > /var/www/band/backup/$(date +%Y-%m-%d-%H%M)-dump_sisbol.sql
      if [ $? -eq 0 ]; then echo "OK" >> $LOG; fi
         /usr/bin/rsync -avz --delete /var/www/band/backup/ $DIRBKP/$dir/database/ >> $LOG


     # backup dos arquivos pdf
     echo -ne "--> Gerando Backup dos arquivos pdf..." >> $LOG
      for dir in {alteracao,boletim,nota_boletim}; 
      do
          /usr/bin/rsync -avz --delete --exclude '*indice*' /var/www/band/$dir/ $DIRBKP/pdf/$dir/ >> $LOG
      done
      if [ $? -eq 0 ]; then echo "OK" >> $LOG; fi
         /usr/bin/rsync -avz --delete $ARQUIVOS $DIRBKP/config/ >> $LOG


      #compactar arquivos de bkp
  echo -ne "--> Compactando arquivos e database..." >> $LOG
  /bin/tar -czvf $ARQUIVO_TAR_GZ $DIRBKP/*
  if [ $? -eq 0 ]; then echo "OK" >> $LOG; fi
  echo "----------------------------------------" >> $LOG
}



enviaParaServidorBackup() {
      echo -ne "--> Enviando Backup do Servidor bkp..." >> $LOG
  /usr/bin/rsync -avz $ARQUIVO_TAR_GZ $DESTINO_REMOTO #dir remoto
  if [ $? -eq 0 ]; then echo "OK" >> $LOG; fi

}


apagaBackupAntigo() {
  echo -ne  "--> Excluindo arquivos de backup antigos..." >> $LOG

      # arquivos sql, tar.gz e log antigos
      /usr/bin/find /var/www/band/backup/ -maxdepth 1 -name "*.sql" -type f -mtime $DIAS_BKP -exec rm -rf {} \;
  /usr/bin/find $DIRBKP -name "log.*" -type f -mtime $DIAS_BKP -exec rm -f {} \;
  /usr/bin/find $DIRBKP -name "*.tar.gz" -type f -exec rm -f {} \;
  if [ $? -eq 0 ] ; then
          echo "OK" >> $LOG
     else
          echo "Nao ha arquivos antigos ou ocorreu algum erro" >> $LOG
     fi
}


apaga_arquivos_gerados_indices(){
  find $dir_boletim \( -iname "*indice*por_pessoa*.pdf" -o -iname "*indice*por_assunto*.pdf" \) -exec rm {} \;

}


main () {
  carregaDados
  geraBackup
  enviaParaServidorBackup
  apagaBackupAntigo
  apaga_arquivos_gerados_indices

      echo "----------------------------------------" >> $LOG
     echo "--> Data de termino: $(date +%d%H%M%b%y)" >> $LOG
      echo "----------------------------------------" >> $LOG

}

main

exit 0
