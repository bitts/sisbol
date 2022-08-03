#!/bin/bash
# 
# --------------------------------------------
# Criado em: Qua 16/Abr/2018 - 15:00hs
# Autor: Asp Of Marcelo Valvassori BITTENCOURT <bittencourt@1cta.eb.mil.br>
# Manutenção: 
# --------------------------------------------
# 
# Propósito Script:  
# corrigir problemas do SISBOL 
# 
# Histórico: 
#   v1.0 - Pequenas correções para sisbol com problemas na acentuação de documentos
#
# Licença: GPL

# Inicialização das variáveis GLOBAIS
START="$(date)"
VERSAO=$(grep '^#   v' $0 | tail -n 1 | cut -d"-" -f1 | tr -d "#v") 
SOBRE="
---------------------------------------------------------------------\n
Correções do \033[0;32mSISBOL\033[0m $VERSAO [04/2018]\n\n

Copyright © 2018 Free Software Foundation, Inc.\n
Licença GPLv3+: GNU GPL versão 3 ou posterior <http://gnu.org/licenses/gpl.html>\n
Este software é livre: você é livre para mudá-lo e redistribuí-lo.\n
NÃO HÁ GARANTIA, para a extensão permitida por lei.\n\n

Escrito por Asp Of Marcelo Valvassori BITTENCOURT.\n
\t << bittencourt@1cta.eb.mil.br >> \n
\033[1;33m1º CTA\033[0m - Sessão de Gerenciamento das Operações\n
(sgo@1cta.eb.mil.br) \n
1º Centro de Telemática de Área \n
Porto Alegre - RS | BRASIL \n
Exercito Brasileiro - 3º RM \n
\n\n

Não executar em ambiente de produção!! \n\n

\033[1;31mATENÇÃO\033[0m: É recomendado a realização de \033[4mBackup dos Arquivos do Sistema e da Base de Dados\033[0m do \033[0;32mSISBOL\033[0m de forma independente \033[4msem a utilização do Script\033[0m, uma vez que caso o servidor não possua espaço em disco os backups podem não serem realizados.\n\n
Erros de permissões podem acontecer dependendo da forma como o servidor foi configurado\n\n
O script deve ser execudado com usuário \033[01;34mROOT\033[0m.\n\n
Composto por dois arquivos:\n
\t -\033[1;33mcrrg_acentos_db.sql\033[0m\n
\t -\033[1;33m`basename $0`\033[0m\n
\n
O Script tem por objetivo auxiliar usuários menos experiêntes na aplicação das correções e é composto pelas seguintes rotinas:\n\n
\t -Busca do arquivo de configuração (arquivo \033[1;33msisbol.ini\033[0m) e exibe os valores de conexão com o banco de dados MySQL, utilizado pelo sistema;\n
\t -Backup da Base de Dados e compactação (TAR) do arquivo;\n
\t -Backup dos arquivos do Sistema e compactação (TAR) dos arquivos;\n
\t -Execução de Script SQL com replace de caracteres de codificação não compativeis com o sistema SISBOL, update nas tabelas: \033[1;33mMATERIA_BI, ASSUNTO_ESPEC, ASSUNTO_GERAL\033[0m, onde existe a possibilidade de possuirem valores gravados de forma errada na base de dados;\n
\t -Aplicação de correção (search and replace) em arquivos PHP com erro de programação.\n
\t -Logs de execução de etapas/warning/error do script de correção. O script gera log de todas as atividades executadas em arquivo.
\n
\n
POSSÍVEIS MELHORIAS:\n
\t - Utilização do getopts para tratamento de parametros e/ou argumentos na execução do script.\n
\t - Utilização dos valores coletados do arquivo INI para a realização de backups da base de dados e execução de script SQL de correção da Base de Dados do SISBOL.\n
\t - Realização da compactação do backup da base de dados somente após verificação do arquivo.\n
\t - Criação de \033[1;31mTrigger AFTER INSERT e AFTER UPDATE\033[0m das tabelas (\033[1;33mMATERIA_BI, ASSUNTO_ESPEC, ASSUNTO_GERAL\033[0m) que podem acontecer novos erros de gravação de dados (disponiveis somente para certas versões do MySQL);\n
\t - Criação de Logs em arquivo html para verificação via editor
\t - Verificação de versão do MySQL para aplicação de script de correção do banco de dados de acordo com a versão. Apartir da versão 5.5 do MySQL é possivel utilizar trigger que altera valores da própria tabela. Ideia é utilizar AFTER INSERT / AFTER UPDATE para alterações nas tabelas/campos:\n
\n\t	- material_bi:
\n\t\t		- texto_abert
\n\t\t		- texto_fech
\n\t
\n\t	- assunto_espec
\n\t\t		- descricao
\n\t\t		- texto_pad_abert
\n\t\t		- texto_pad_fech
\n\t
\n\t	- assunto_geral
\n\t\t		- descricao
\n
PROJETO ABANDONADO:\n
\t - Programação não é foco dos Centros de Telemática.\n
Encaminhar solicitações de melhorias ou correções do SISBOL adiretamente ao CDS <http://www.cds.eb.mil.br/>\n
\n
---------------------------------------------------------------------\n
"

MENSAGEM_USO="
\n Script para correções do SISBOL Versão 2.5\n
\n
ATENÇÃO: Não executar este script diretamente em ambiente de produção!! Teste-o antes em outro ambiente.\n\n
Uso: `basename $0` [OPÇÕES]\n\n
   \tOPÇÕES:\n
   \t -a,  --ajuda       \t\tMostra esta tela e sai\n
   \t -v,  --versao     \t\tMostra a versão do programa e sai\n
   \t -s,  --set     	\t\tSeta arquivo de configuração do SISBOL\n
   \t -i,  --info     \t\tInformações e orientações do Script de Correções\n
   \t -db, --backupbase     \tBackup da Base de Dados do SISBOL\n
   \t -bs, --backupsystem     \tBackup dos arquivos do SISBOL\n
   \t -cb, --corrigebase     \tCorrige a base de dados do SISBOL aplicando script SQL ao banco\n
   \t -cs, --corrigesystem     \tCorrige arquivos do SISBOL aplicando um seach and replace nos erros de codificação \n


\n ATENÇÃO as mensagens e solicitações de confirmação!!\n\n
RECOMENDA-SE a leitura da opção -i (informações sobre o script) antes execuação do mesmo.
\n\n
Correções e melhorias para <bittencourt@1cta.eb.mil.br> 
"
ERRO="\n
$0: opção inválida -- '`echo "$1" | tr -d "-" `'\n
Tente '$0 --help' para mais informação.\n
"

DB_SGBD=""
DB_HOST=""
DB_USER=""
DB_PSWD=""
DB_BASE=""
DB_FDBK="/var/www/"

FD_SISBOL="/var/www/band/"

MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"




function flog(){
	local log="${DB_FDBK}log.txt"
	local txt=$1
	echo "[`date +%d-%m-%y_%H:%M:%S`] $txt" >> $log
}

function coloredEcho(){
    local exp=$1;
    local color=$2;
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput setaf $color;
    echo $exp;
    tput sgr0;
}

function loading(){
	echo "" 
	echo -n "Loading" # Escreva sem pular linha
	for i in $(seq 1 1 5); # Laço de repetição FOR repita começando de "1", de 1 em 1 até "5"
	do # Faça
		echo -n "." # Escreva . sem pular linha
		sleep 01 # Pause 1 segundo
		echo -ne "" # Gambiarra, atualize a tela
	done # Feito
	echo ""
}
function hr(){
  printf '=%.0s' {1..100}
  printf "\n"
}

function sair(){
	#HORA FIM DO SCRIPT --OPCIONAL, APENAS PARA SABER QUANDO COMEÇOU A EXECUTAR E TERMINOU
	flog "====[Fim da execução do programa]===="
	END="$(date)"
	exit 0;
}

function BackupSYS(){
	flog "Inicio do Backup dos arquivos do sistema."
	folderbk=$DB_FDBK

	if [ -n "$folderbk" ];
	then
		echo "Backup dos arquivos será realizado na pasta: $DB_FDBK"
		echo -n "Informar novo caminho? [S] Sim [N] Não "
		read conf; 

		if [ $conf == 'S' || $conf == 's' || $conf == 'Sim' || $conf == 'sim' ] ;
		then 
			flog "É necessário informar o local de destino dos backups que serão relizado.";
			while((1));
			do
				echo -n "Informe um caminho valido: "
				read folderbk; 

				if  [ -d "$folderbk" ];
				then 
					break
				fi	
			done

		fi
	else if [ -s "$folderbk" ];
		then
			flog "É necessário informar o local de destino dos backups que serão relizado.";
			echo "Informe o novo caminho para Backup dos Arquivos: "
			read folderbk; 

			while((1));
			do
				echo -n "Informe um caminho valido: "
				read folderbk; 

				if  [ -d "$folderbk" ];
				then 
					break
				fi	
			done
			flog "Destino dos backups dos arquivos do sistema definido como [ ${folderbk} ].";
		fi
	fi
	#setando o nome do arquivo de destino
	minhadata=$(date +'%F');
	nomearq="SISBOL_backupSYS-"$minhadata;
	#compactando o arquivo
	coloredEcho "Compactando arquivos, essa ação pode levar algum tempo..." grenn
	flog "Realizando o backups e capactação dos arquivos do sistema.";
	coloredEcho "<< Para cancelar a operação precione CTRL + C >>" red

	hr

	tar -vczf $folderbk/$nomearq.tar $FD_SISBOL
	if [ $? -eq 0 ]
	then
	    	coloredEcho "Backup realizado com sucesso. Destino: " $folderbk/$nomearq ".tar" green
		flog "Backup realizado com sucesso. Destino:  [ ${folderbk}/${nomearq}.tar ]"
	fi
}

function BackupDBD(){
	flog "Inicio do Backup da Base de Dados do Sisbol."
	#1 = host | 2 = user | 3 = password | 4 = database
	if [[ $1 -ne "" && $2 -ne "" && $3 -ne "" && $4 -ne "" ]];
	then	
		DB_HOST=$1
		DB_USER=$2
		DB_PSWD=$3
		DB_BASE=$4
	else
		
		echo ""
		echo "A pasta de destino do backup sera: " $DB_FDBK
		echo -n "Informar novo caminho? [S] Sim [N] Não "
		read conf; 
		if [[ $conf == 'S' || $conf == 's' || $conf == 'Sim' || $conf == 'sim' ]] ;
		then 
			flog "É necessário informar o local de destino dos backups que serão relizado.";
			while((1));
			do
				echo -n "Informe o novo caminho para o Backup da Base de Dados: "
				read folderbk; 

				if  [ -d "$folderbk" ];
				then 
					break
				fi	
			done
		
		else
			flog "Pasta de destino dos backups definida como ${folderbk}.";
			folderbk=$DB_FDBK
		fi
	fi

	minhadata=$(date +'%F');
	nomearq="SISBOL_backupDTB-"$minhadata;

	echo ""
	coloredEcho "Para a realização do Backup da Base de Dados é necessário informar os dados para conexão" white
	
	read -p "HOST : " DB_HOST
	read -p "USUARIO : " DB_USER
	read -p "PASSWORD : " DB_PSWD
	read -p "DATABASE : " DB_BASE


	BACKUP="$($MYSQLDUMP -u$DB_USER -h$DB_HOST --password=$DB_PSWD -v -B $DB_BASE > $folderbk$nomearq.sql)"

	#aqui necessario realizar teste se comando de backup foi realizado com sucesso e somente entao realizar a compactação do arquivo
	flog "Compactando o arquivo SQL gerado com o backup da base de dados do sistema."
	gzip -f $folderbk$nomearq".sql"
	flog "Fim do Backup da Base de Dados do Sisbol."
}

function get_ini_value() {
# search a list of ini_files for the desired id, returning the first match
# w/o regard for sections so it also works for setup.py files.
# Strips enclosing white space and quotes and trailing commas

# params:
# $1 -- the section (if any)
# $2 -- the key
# $* -- one or more ini files

	section=$1
	key=$2
	shift; shift
	files=$*

	for ini_file in $files
	do
		[ -f "$ini_file" ] || continue
		value=$(
			if [ -n "$section" ]; then
				sed -n "/^\[$section\]/, /^\[/p" $ini_file
			else
				cat $ini_file
			fi |
			egrep "^ *\b$key\b *=" |
			head -1 | cut -f2 -d'=' |
			sed 's/^[ "'']*//g' |
			sed 's/[ ",'']*$//g' )

	if [ -n "$value" ]; then
		echo $value
		return
	fi
	done
}

function testeINI(){
	flog "Inicio da verificação dos dados do arquivo sisbol.ini."
	#echo "Validando arquivo de configuração: " $1 
	if [ $1 != "" ];
	then
		FILE=$1

		flog "Arquivo $1 encontrado... verificando dados."

		SGBD=$(awk -F"=" '/sgbd/ {print $2}' $FILE | tr -d ' '| sed 's/ //g' | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/^[ \t]*//')
		name_sgbd=$(echo $SGBD | tr "=" "\n")
		for addr in $name_sgbd
		do
			dtr0=$addr				
		done
		SGBD=$dtr0
		flog "Sistema de Gerenciamento de Banco de dado localizado: ${SGBD}"
		#################################################
		DATABASE_NAME=$(awk -F"=" '/database/ {print $2}' $FILE | tr -d ' '| sed 's/ //g' | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/^[ \t]*//')
		#echo "===>" ${#DATABASE_NAME[@]}    <-- tamanho de vetor
		name_db=$(echo $DATABASE_NAME | tr "=" "\n")
		for addr in $name_db
		do
			dtr1=$addr				
		done
		DATABASE=$(echo $dtr1)
		flog "Nome da Base de Dados localizado: ${DATABASE}"	
		#################################################
		DATABASE_USER=$(awk -F"=" '/user/ {print $2}' $FILE | tr -d ' '| sed 's/ //g' | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/^[ \t]*//')
		user_db=$(echo $DATABASE_USER | tr "=" "\n")
		for addr in $user_db
		do
			dtr2=$addr				
		done
		USER=$(echo $dtr2)
		flog "Usuário do Banco de dado localizado: ${USER}"
		#################################################
		DATABASE_HOST=$(awk -F"=" '/host/ {print $2}' $FILE | tr -d ' '| sed 's/ //g' | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/^[ \t]*//')
		host_db=$(echo $DATABASE_HOST | tr "=" "\n")
		for addr in $host_db
		do
			dtr3=$addr		
		done
		HOST=$(echo $dtr3)
		flog "HOST do Banco de dado localizado: ${USER}"
		#################################################
		DATABASE_PSWD=$(awk -F"=" '/password/ {print $2}' $FILE | tr -d ' '| sed 's/ //g' | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/^[ \t]*//')
		pswd_db=$(echo $DATABASE_PSWD | tr "=" "\n")
		for addr in $pswd_db
		do
			dtr4=$addr				
		done
		PSWD=$(echo $dtr4)
		flog "Password do Banco de dado localizado: ${USER}"
		#################################################
		echo ""
		coloredEcho "Propriedades da conexão com o Banco de Dados localizadas no arquivo: [$1]" green
		echo " | sgbd: " $SGBD
		echo " | usuario: " $USER 
		echo " | host: " $HOST 
		echo " | password: " $PSWD 
		echo " | database: " $DATABASE

		
		#echo -n "Confirmar dados? [S] Sim [N] Não: "
		#read conf; 

		#if [[ $conf == 'S' || $conf == 's' || $conf == 'Sim' || $conf == 'sim' ]] ;
		#then 
		#	DB_SGBD=$SGBD
		#	DB_HOST=$HOST
		#	DB_USER=$USER 
		#	DB_PSWD=$PSWD
		#	DB_BASE=$DATABASE
		#else
		#	echo ""
		#	coloredEcho "Para a realização do Backup da Base de Dados é necessário informar os dados para conexão" white
	
		#	read -p "HOST : " DB_HOST
		#	read -p "USUARIO : " DB_USER
		#	read -p "PASSWORD : " DB_PSWD
		#	read -p "DATABASE : " DB_BASE
		#fi

#isso aqui não funcionou por que nao consigo utilizar os valores lidos do arquivo INI e gravados nas variaveis, problemas quando realizo a concatenação Variavel/String SQL, foi tentado retirar espaços em branco ate mesmo reatribuir valores a nova variaveis, mas infelizmente não funciona, variavel é como se tivesse sido inclusa com INSERT ligado e sobrescreve o texto ser concatenado com outra string
		

	elif [ $1 == "" ];
	then
		echo "Nenhum arquivo encontrado!"
		flog "Nenhum arquivo sisbol.ini encontrado."
	fi
	flog "Inicio da verificação dos dados do arquivo sisbol.ini."
}


function search_file_config(){
	flog "Inicio da localização do arquivo com as configurações do SISBOL."
	coloredEcho "Procurando arquivo com configurações do SISBOL..."  yellow

	local_ini=$(find / -iname sisbol.ini 2> /dev/null)

	if [ ${#local_ini[@]} -gt 1 ];
	then  
		flog "Multiplos arquivos sisbol.ini encontrados."
		echo "Arquivos encontrados: "
		a=0
		for line in $local_ini
		do 
			a=$((a+1))
			vetor[ $a ]=$line 
			echo "[" $a "] " $line 
		done
	
		echo "Selecione um dos arquivos: "
		read opcao; 
		echo "Arquivo de configuração selecionado: " ${vetor[ $opcao ]};
		testeINI ${vetor[ $opcao ]} 
	else
		flog "Somente um arquivo sisbol.ini encontrado."
		testeINI $local_ini
	fi		
	flog "Fim da localização do arquivo com as configurações do SISBOL."
}

function verificaRequisitos(){
	FLAG=false

	flog "Inicio da verificação de pré-requisitos para execução do script."
	echo -e "\n Verificação de pre-requisitos...."

	FILE='crrg_acentos_db.sql'

	echo -e "\n Verificando a existência do arquivo com scripts de correções da base de dados..."
	if [ -e "$FILE" ]; 
	then
		flog "Verificação do arquivo ${FILE} com correções SQL. Arquivo encontrado."
		echo -e "\n\t [\033[01;32mOK\033[0m] Arquivo $FILE referente a correções no banco de dados encontrato."
	else
		echo -e "\n\t [\033[1;31mERRO\031[0m] O arquivo $FILE não existe e as correções na base de dados não podem ser realizadas sem a utilização desse arquivo." red
		flog "Verificação do arquivo ${FILE} com correções SQL. Arquivo não encontrado."
		FLAG=true
	fi


	echo -e "\n Verificando a existência do arquivo de configurações do SISBOL..."
	
	local_ini=$(find / -iname sisbol.ini 2> /dev/null)

	if [ ${#local_ini[@]} -ge 1 ];
	then  
		flog "Arquivo de configurações do Sisbol encontrado."
		echo -e "\n\t [\033[01;32mOK\033[0m] Arquivo sisbol.ini referente a configurações do SISBOL encontrado."
	else
		flog "Arquivo de configurações do Sisbol não encontrado."
		echo -e "\n\t [\033[1;31mERRO\031[0m] O arquivo sisbol.ini não existe ou não foi encontrado."
		FLAG=true
	fi

	echo -e "\n Verificando permissão de escrita/gravação da pasta corrente para gravação dos arquivos de backup."
	
	if [ -w `pwd` ]; 
	then 
		flog "Verificação de permissão da pasta para leitura/escrita. Pasta com permissão."
		echo -e "\n\t [\033[01;32mOK\033[0m] A pasta corrente possui permissão de escrita/gravação e pode salvar os arquivos de backup."; 
	else 
		flog "Verificação de permissão da pasta para leitura/escrita. Sem permissão na pasta."
		echo -e "\n\t [\033[1;31mERRO\031[0m] A pasta atual não possui permissão de escrita/gravação, é necessário permissões para o funcionamento pleno do script."; 
		FLAG=true
	fi

	echo -e "\n Verificando se Script de correções do SISBOL já não foi aplicado."

	fCorr=$(grep -iPo 'Asp of Bittencourt' $DB_FDBK/band/sobre.php)
	if [ "$fCorr" != "" ];
	then 
		UPdate=$(stat -c %y $DB_FDBK/band/sobre.php)

		flog "O sistema já esta atualizado com as correções geradas pelo Script. Data da atualização [${UPdate}]"
		echo -e "\n\t [\033[1;31mERRO\033[0m] O sistema já esta atualizado com as correções geradas pelo Script. Data da atualização [${UPdate}]."; 
		FLAG=true
	else
		echo -e "\n\t [\033[01;32mOK\033[0m] O Script de correção do SISBOL ainda não executado."; 
		flog "Script de correções do SISBOL ainda não foi executado."
	fi

	flog "Fim da verificação de pré-requisitos para execução do script."

	if [ $FLAG == true ]; 
	then 
		flog "Script finalizado por falta de pré-requisitos, erros e/ou falhas no script."
		echo -e "\nInfelizmente o script não podera ser executado por falta de pre-requisitos."
		echo -e "\nFinalizando o Script..."
		sair
	else 
		flog "Todos os pre-requisitos para execução do Script verificados."
	fi
	
}


function corrigeDBSISBOL(){
	flog "Inicio da execução do script SQL de correção da Base de Dados."
	echo "Inicio do Script de correção de acentuação de valores armazenadas na base de dados... "

	#FILE='correcao_acentos-SISBOL.sql'
	FILE='crrg_acentos_db.sql'

	if [ -e "$FILE" ] ; then

		BACKUP="$($MYSQL -u $DB_USER -h $DB_HOST --password=$DB_PSWD $DB_BASE < correcao_acentos-SISBOL.sql)"
		flog "Arquivo ${FILE} encontrado e script executado sem tratamento de erros oriundos do servidor"
	else
		coloredEcho "o arquivo $FILE não existe e as correções na base de dados não podem ser realizadas." red
		flog "O arquivo $FILE não existe ou não foi encontrado."
	fi

	flog "Fim da execução do script SQL de correção da Base de Dados."
	coloredEcho "Fim da execução do script SQL de correção da Base de Dados" blue
}

function corrigeSISBOL(){
	flog "Inicio do Script de correção de arquivos PHP."

	echo ""

	if [ -d "$DB_FDBK" ];
	then 
		while((1));
		do
			echo -n "Informe o caminho de onde esta localizado o sistema do SISBOL: "
			read DB_FDBK; 

			if  [ -d "$DB_FDBK" ];
			then 
				break
			fi	
		done
	fi

	flog "Caminho da pasta do sistema definido como ${DB_FDBK}band/"

	echo "Caminho da pasta do sistema: ${DB_FDBK}band/"

	if [ -d "${DB_FDBK}band/" ];
	then 
		flog "Verificando se o sistema já não esta atualizado com as correções."
		#verificando se o sistema ja foi atualizado
		fCorr=$(grep -iPo 'Asp of Bittencourt' $DB_FDBK/band/sobre.php)
		if [ "$fCorr" != "" ];
		then 
			UPdate=$(stat -c %y $DB_FDBK/band/sobre.php)
			echo -e "\n\033[01;32mO script de correções do Sistema SISBOL, foi executado em ${UPdate}.\033[0m"
			echo -e "\n\033[01mEtapa de correções nos arquivos do sistema finalizada.\033[0m\n" 
			flog "O sistema já esta atualizado com as correções geradas pelo Script. Data da atualização [${UPdate}]"
		else
			#inicio da verificação de existencia dos arquivos
			flog "Verificando a existencia dos arquivos do sistema para correção."
			#----> ajax_assunto_geral.php
			if  [ -e "$DB_FDBK/band/ajax_assunto_geral.php" ]; then 
				echo -e "[\033[01;32mOK\033[0m] Arquivo ${DB_FDBK}band/ajax_assunto_geral.php encontrado."
				flog "Arquivo encontrado: ${DB_FDBK}band/ajax_assunto_geral.php"
			else 
				echo -e "[\033[1;31mERRO\031[0m] Arquivo ${DB_FDBK}band/ajax_assunto_geral.php não encontrado."
				flog "Arquivo não encontrado: ${DB_FDBK}band/ajax_assunto_geral.php"
			fi
			#----> ajax_materia_bi.php			
			if  [ -e "$DB_FDBK/band/ajax_materia_bi.php" ]; then 
				echo -e "[\033[01;32mOK\033[0m] Arquivo ${DB_FDBK}band/ajax_materia_bi.php encontrado."
				flog "Arquivo encontrado: ${DB_FDBK}band/ajax_materia_bi.php"
			else 
				echo -e "[\033[1;31mERRO\031[0m] Arquivo ${DB_FDBK}band/ajax_materia_bi.php não encontrado."
				flog "Arquivo não encontrado: ${DB_FDBK}band/ajax_materia_bi.php"
			fi
			#----> ajax_aprovamatbi.php
			if  [ -e "$DB_FDBK/band/ajax_aprovamatbi.php" ]; then 
				echo -e "[\033[01;32mOK\033[0m] Arquivo ${DB_FDBK}band/ajax_aprovamatbi.php encontrado."
				flog "Arquivo encontrado: ${DB_FDBK}band/ajax_aprovamatbi.php"
			else 
				echo -e "[\033[1;31mERRO\031[0m] Arquivo ${DB_FDBK}band/ajax_aprovamatbi.php não encontrado."
				flog "Arquivo não encontrado: ${DB_FDBK}band/ajax_aprovamatbi.php"
			fi
			#----> ajax_cad_assunto_espec.php
			if  [ -e "$DB_FDBK/band/ajax_cad_assunto_espec.php" ]; then 
				echo -e "[\033[01;32mOK\033[0m] Arquivo ${DB_FDBK}band/ajax_cad_assunto_espec.php encontrado."
				flog "Arquivo encontrado: ${DB_FDBK}band/ajax_cad_assunto_espec.php"
			else 
				echo -e "[\033[1;31mERRO\031[0m] Arquivo ${DB_FDBK}band/ajax_cad_assunto_espec.php não encontrado."
				flog "Arquivo não encontrado: ${DB_FDBK}band/ajax_cad_assunto_espec.php"
			fi
			#----> ajax_inc_mat_bol.php
			if  [ -e "$DB_FDBK/band/ajax_inc_mat_bol.php" ]; then 
				echo -e "[\033[01;32mOK\033[0m] Arquivo ${DB_FDBK}band/ajax_inc_mat_bol.php encontrado."
				flog "Arquivo encontrado: ${DB_FDBK}band/ajax_inc_mat_bol.php"
			else 
				echo -e "[\033[1;31mERRO\031[0m] Arquivo ${DB_FDBK}band/ajax_inc_mat_bol.php não encontrado."
				flog "Arquivo não encontrado: ${DB_FDBK}band/ajax_inc_mat_bol.php"
			fi
			#----> congerarboletim.php
			if  [ -e "$DB_FDBK/band/classes/band/congerarboletim.php" ]; then 
				echo -e "[\033[01;32mOK\033[0m] Arquivo ${DB_FDBK}band/classes/band/congerarboletim.php encontrado."
				flog "Arquivo encontrado: ${DB_FDBK}band/classes/band/congerarboletim.php"
			else 
				echo -e "[\033[1;31mERRO\031[0m] Arquivo ${DB_FDBK}band/classes/band/congerarboletim.php não encontrado."
				flog "Arquivo não encontrado: ${DB_FDBK}band/classes/band/congerarboletim.php"
			fi
			#fim da verificação de existencia dos arquivos 


			flog "Aplicando correções/alterações nos arquivos do sistema, correções Search and Replace."

			coloredEcho "Aplicando correções ao Sistema do SISBOL..." yellow
			coloredEcho "Correções em arquivos PHP - Search and Replace" yellow

			correcao=$(
			sed -i 's/utf8_encode($assuntoGeral->getDescricao())/$assuntoGeral->getDescricao()/g' $DB_FDBK/band/ajax_assunto_geral.php && 
			sed -i 's/utf8_encode($AssuntoEspec->getDescricao())/$AssuntoEspec->getDescricao()/g' $DB_FDBK/band/ajax_assunto_geral.php &&
			sed -i 's/utf8_encode($UltimoAssuntoEspecifico->getDescricao())/$UltimoAssuntoEspecifico->getDescricao()/g' $DB_FDBK/band/ajax_assunto_geral.php
		
			sed -i 's/echo ($assuntoEspec->getTextoPadAbert())/echo utf8_decode($assuntoEspec->getTextoPadAbert())/g' $DB_FDBK/band/ajax_materia_bi.php &&  
			sed -i 's/echo ($assuntoEspec->getTextoPadFech())/echo utf8_decode($assuntoEspec->getTextoPadFech())/g' $DB_FDBK/band/ajax_materia_bi.php &&  
		
			sed -i 's/\.$materiaBi->getTextoAbert()\./\.utf8_decode($materiaBi->getTextoAbert())\./g' $DB_FDBK/band/ajax_aprovamatbi.php &&
			sed -i 's/\.$materiaBi->getTextoFech()\./\.utf8_decode($materiaBi->getTextoFech())\./g' $DB_FDBK/band/ajax_aprovamatbi.php && 
	   
			sed -i 's/echo $assuntoEspecifico->getTextoPadAbert()\./echo utf8_decode($assuntoEspecifico->getTextoPadAbert())\./g' $DB_FDBK/band/ajax_cad_assunto_espec.php &&
			sed -i 's/echo $assuntoEspecifico->getTextoPadFech()\;/echo utf8_decode($assuntoEspecifico->getTextoPadFech())\;/g' $DB_FDBK/band/ajax_cad_assunto_espec.php &&
			sed -i 's/echo trim($texto)\;/echo utf8_decode(trim($texto))\;/g' $DB_FDBK/band/ajax_cad_assunto_espec.php &&

			sed -i 's/$arq = $fachadaSist2->gerarMateriaBi($materiaBi)\;/$materiaBi->setTextoAbert( utf8_decode($materiaBi->getTextoAbert()) )\;\n\t$materiaBi->setTextoFech( utf8_decode($materiaBi->getTextoFech()) )\;\n\t$arq = $fachadaSist2->gerarMateriaBi($materiaBi)\; /g' $DB_FDBK/band/ajax_elabomatbi2.php &&
		
			sed -i 's/\.$materiaBi->getTextoFech()\./\.utf8_decode($materiaBi->getTextoFech())\./g' $DB_FDBK/band/ajax_inc_mat_bol.php &&
			sed -i 's/\.$materiaBi->getTextoAbert()\./\.utf8_decode($materiaBi->getTextoAbert())\./g' $DB_FDBK/band/ajax_inc_mat_bol.php &&

			sed -i 's/\.$materiaBi->getTextoFech()\./\.utf8_decode($materiaBi->getTextoFech())\./g' $DB_FDBK/band/ajax_exc_mat_bol.php &&
			sed -i 's/\.$materiaBi->getTextoAbert()\./\.utf8_decode($materiaBi->getTextoAbert())\./g' $DB_FDBK/band/ajax_exc_mat_bol.php &&


			sed -i "98a\<li><B>Corre&ccedil;&otilde;es (05\/2018)<\/B><blockquote><p>Asp Of Bittencourt (1&ordm; CTA)<\/p><\/blockquote><\/li>" $DB_FDBK/band/sobre.php &&
			sed -i "404a\\/********* correcoes [05/2018] **********\/" $DB_FDBK/band/classes/band/congerarboletim.php &&
			sed -i "405a\$this->materiaBi->setTextoFech(utf8_decode(\$this->materiaBi->getTextoFech()))\;" $DB_FDBK/band/classes/band/congerarboletim.php &&
			sed -i "406a\$this->materiaBi->setTextoAbert(utf8_decode(\$this->materiaBi->getTextoAbert()))\;" $DB_FDBK/band/classes/band/congerarboletim.php &&


			sed -i "451a\\/********* correcoes [05/2018] **********\/" $DB_FDBK/band/classes/band/congerarboletim.php &&
			sed -i "452a\$pGrad->setDescricao( utf8_decode( \$pGrad->getDescricao() ) )\;" $DB_FDBK/band/classes/band/congerarboletim.php &&
			sed -i "453a\$pessoaMateriaBi->setTextoIndiv(utf8_decode(\$pessoaMateriaBi->getTextoIndiv()))\;" $DB_FDBK/band/classes/band/congerarboletim.php &&
			sed -i "454a\\/********* correcoes [05/2018] **********\/" $DB_FDBK/band/classes/band/congerarboletim.php
	 		)
		
			echo -e "Arquivos corrigidos...\n"
			echo -e "\t ${DB_FDBK}band/ajax_assunto_geral.php" 
			echo -e "\t ${DB_FDBK}band/ajax_materia_bi.php"
			echo -e "\t ${DB_FDBK}band/ajax_aprovamatbi.php"
			echo -e "\t ${DB_FDBK}band/ajax_cad_assunto_espec.php"
			echo -e "\t ${DB_FDBK}band/ajax_elabomatbi2.php"
			echo -e "\t ${DB_FDBK}band/ajax_inc_mat_bol.php"
			echo -e "\t ${DB_FDBK}band/ajax_exc_mat_bol.php"
			echo -e "\t ${DB_FDBK}band/sobre.php"
			echo -e "\n"
		fi
	else
		coloredEcho "Caminho inválido, pasta não localizada: ${DB_FDBK}band/ é preciso informar a pasta onde esta localizada o sistema do SISBOL." red
		flog "Caminho informado como pasta do sistema é invalido. Caminho informado [ ${DB_FDBK}band/ ]"
	fi

	echo "Fim do Script de correção de arquivos PHP."
	flog "Fim do script de correção de arquivos PHP."
}


if [ $# -eq 0 ]; then 
	flog "====[Inicio da execução do Script]===="
	flog "Execução normal do Script, todas as opções, sem passagem de parametros."
	clear #Limpar a tela
   	echo -e $MENSAGEM_USO 
	coloredEcho "Executando script..." yellow
	loading
	verificaRequisitos
	search_file_config

	BackupDBD
	BackupSYS
	corrigeDBSISBOL
	corrigeSISBOL
	coloredEcho "Fim da execução script..." blue
	sair
fi

while [ -n "$1" ]; do
	flog "====[Inicio da execução do Script por parametros]===="
	flog "Seleção de parametros, opção selecionada: ${1}"
	clear
	case "$1" in

	      	-a|--ajuda) 
			flog "PARAM: Mensagem de uso do sistema exibido."
			echo -e $MENSAGEM_USO 
		        sair
		        ;;
	      	-v|--versao) 
			flog "PARAM: Mensagem Sobre o sistema exibido."
			echo -e $SOBRE 
			sair
			;;
		-s|--set) 
			flog "PARAM: Localizando arquivo de configuração do SISBOL."
			search_file_config
			sair
			;;
		-db|--backupbase) 
			flog "PARAM: Backup da base de dados."
			BackupDBD 
			sair
			;;
		-bs|--backupsystem) 
			flog "PARAM: Backup dos arquivos do sistema."
			BackupSYS 
			sair
			;;
		-cb|--corrigebase) 
			search_file_config
			BackupDBD
			corrigeDBSISBOL 
			sair
			;;
		-cs|--corrigesystem) 
			flog "PARAM: Correções nos arquivo do sisbol."
			corrigeSISBOL 
			sair
			;;
		-i|--info) 
			flog "PARAM: informações sobre o sistema."
			echo -e $MENSAGEM_USO 
			echo -e $SOBRE 
			sair
		        ;;
		-p|--pre) 
			flog "PARAM: verificação dos requisitos do sistema."
			verificaRequisitos
			sair
		        ;;		


	      	*) echo -e $ERRO ; 
		 	;;
   esac 
   shift
done

sair 

