# Correções SISBOL 2.5
Script Bash de correções diversas para SISBOL versão 2.5 

(SCRIPT OBSOLETO e sem manutenção)


Não executar em ambiente de produção!!

ATENÇÃO: É recomendado a realização de Backup dos Arquivos do Sistema e da Base de Dados do SISBOL de forma independente sem a utilização do Script, uma vez que caso o servidor não possua espaço em disco os backups podem não serem realizados.

Erros de permissões podem acontecer dependendo da forma como o servidor foi configurado

O script deve ser execudado com usuário ROOT.

Composto por dois arquivos:

  - crrg_acentos_db.sql
  - crrg_sisbol.sh
  
O Script tem por objetivo auxiliar usuários menos experiêntes na aplicação das correções e é composto pelas seguintes rotinas:

  - Busca do arquivo de configuração (arquivo sisbol.ini) e exibe os valores de conexão com o banco de dados MySQL, utilizado pelo sistema;
  - Backup da Base de Dados e compactação (TAR) do arquivo;
  - Backup dos arquivos do Sistema e compactação (TAR) dos arquivos;
  - Execução de Script SQL com replace de caracteres de codificação não compativeis com o sistema SISBOL, update nas tabelas: MATERIA_BI, ASSUNTO_ESPEC, ASSUNTO_GERAL, onde existe a possibilidade de possuirem valores gravados de forma errada na base de dados;
  - Aplicação de correção (search and replace) em arquivos PHP com erro de programação.
  - Logs de execução de etapas/warning/error do script de correção. O script gera log de todas as atividades executadas em arquivo.


POSSÍVEIS MELHORIAS:
   - Utilização do getopts para tratamento de parametros e/ou argumentos na execução do script.
   - Utilização dos valores coletados do arquivo INI para a realização de backups da base de dados e execução de script SQL de correção da Base de Dados do SISBOL.
   - Realização da compactação do backup da base de dados somente após verificação do arquivo.
   - Criação de Trigger AFTER INSERT e AFTER UPDATE das tabelas (MATERIA_BI, ASSUNTO_ESPEC, ASSUNTO_GERAL) que podem acontecer novos erros de gravação de dados (disponiveis somente para certas versões do MySQL);
   - Criação de Logs em arquivo html para verificação via editor
   - Verificação de versão do MySQL para aplicação de script de correção do banco de dados de acordo com a versão. Apartir da versão 5.5 do MySQL é possivel utilizar trigger que altera valores da própria tabela. Ideia é utilizar AFTER INSERT / AFTER UPDATE para alterações nas tabelas/campos:
      - material_bi:
      - texto_abert
      - texto_fech
      - assunto_espec
      - descricao
      - texto_pad_abert
      - texto_pad_fech  
      - assunto_geral
      - descricao

PROJETO ABANDONADO:
- Programação não é foco dos Centros de Telemática.
Encaminhar solicitações de melhorias ou correções do SISBOL adiretamente ao CDS <http://www.cds.eb.mil.br/>

