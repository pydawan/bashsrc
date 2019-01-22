#!/bin/bash

#----------------------------------------------#
# Source:           error.sh
# Data:             9 de novembro de 2017
# Desenvolvido por: Juliano Santos [SHAMAN]
# E-mail:           shellscriptx@gmail.com
#----------------------------------------------#

[[ $__ERROR_SH ]] && return 0

source builtin.sh
source struct.sh

readonly __ERROR_SH=1

var error_t struct_t

error_t.__add__ \
	code 		uint \
	line 		uint \
	funcname 	str \
	error 		str

# func error.resume <[bool]option>
#
# Habilita/Desabilita a rotina para tratamento de erro em tempo de execução.
#
# Flags:
#
# false - Se ocorrer um erro, uma mensagem é exibida contendo as informações da
# pilha de rastreamento e a execução do script é interrompida (padrão).
#
# true - Se ocorrer um erro, serão inicializadas as variáveis de rastreamento 
# '__ERR_*' e o script continuará seu fluxo de execução.
#
# Variáveis de rastreamento:
#
# __ERR__ - Status do erro
# __ERR_STACK__ - Funções de desencadeamento
# __ERR_ARG__ - Argumento da função
# __ERR_TYPE__ - Tipo de dado do argumento
# __ERR_VAL__ - Valor do argumento
# __ERR_MSG__ - Mensagem de erro
# __ERR_FUNC__ - Função que provocou o erro
# __ERR_LINE__ - Número da linha onde o erro foi disparado.
# 
# Exemplo:
#
# #!/bin/bash
#
# source os.sh
# 
# var arq os.file
#
# # Desabilitando o tratamento de erro
# error.resume on
#
# # Tentando ler um arquivo que não existe.
# os.open arq '/home/usuario/arquivo_nao_existe.txt' $O_RDONLY
#
# # Testa o status do erro 
# if [ $__ERR__ ]; then
#     echo 'Ops !! Aconteceu algo !!'
#     echo "Encontrei o erro -> $__ERR_MSG__"
#     echo "Aconteceu aqui -> $__ERR_FUNC__"
# fi
#
# Restaurando o tratamento de erro
# error.resume off
#
# ----------------------
# Saida:
#
# Ops !! Aconteceu algo !!
# Encontrei o erro -> erro ao criar o descritor '3'
# Aconteceu aqui -> os.open
#
function error.resume()
{
	getopt.parse 1 "option:bool:+:$1" "${@:2}"
	__ON_ERROR_RESUME=$1
	return 0
}

function error.fatal()
{
	getopt.parse 2 "code:uint:+:$1" "error:str:+:$2" ${@:3}
	error.__output fatal "$1" "$2"
	return $?
}

function error.strerror()
{
	getopt.parse 2 "code:uint:+:$1" "error:str:+:$2" ${@:3}
	error.__output strerr "$1" "$2"
	return $?
}

function error.warn()
{
	getopt.parse 2 "code:uint:+:$1" "error:str:+:$2" ${@:3}
	error.__output warn "$1" "$2"
	return $?
}

function error.format()
{
	getopt.parse -1 "code:uint:+:$1" "fmt:str:+:$2" "exp:str:-:$3" ... "${@:4}"
	error.__output fmt "$1" "$2" "${@:3}"
	return $?
}

function error.info()
{
	getopt.parse 1 "struct:error_t:+:$1" "${@:2}"
	error.__output error_t "$1"
	return $?
}

function error.__output()
{
	local c_def c_red err_msg
	local code line func err

	if [[ $1 == error_t ]]; then
		if [[ $(__type__ $2) == $1 ]]; then
			code=$($2.code)
			line=$($2.line)
			func=$($2.funcname)
			err=$($2.error)
			
			[[ $code ]] || { error.__trace st "$1" 'code' 'uint' "$__ERR_STRUCT_VAL_MEMBER"; return $?; } 
			[[ $line ]] || { error.__trace st "$1" 'line' 'uint' "$__ERR_STRUCT_VAL_MEMBER"; return $?; } 
			[[ $func ]] || { error.__trace st "$1" 'funcname' 'str' "$__ERR_STRUCT_VAL_MEMBER"; return $?; } 
			[[ $err ]] || { error.__trace st "$1" 'error' 'str' "$__ERR_STRUCT_VAL_MEMBER"; return $?; }
		else
			error.__trace def
			return $?
		fi
	fi

	case $__ON_ERROR_RESUME in
		true)
			__ERR__=${code:-$2}
			__ERR_MSG__=${err:-$3}
			__ERR_FUNC__=${func:-${FUNCNAME[2]}}
			__ERR_LINE__=${line:-${BASH_LINENO[1]}}
			;;
		false)
			exec 1>&2
			case $1 in
				fatal)
					echo ---------------------------------
					echo "(ERRO FATAL)"
					echo ---------------------------------
					echo "Script: ${0##*/}"
					echo "Linha: ${BASH_LINENO[1]}"
					echo "Função: ${FUNCNAME[2]}"
					echo "Erro: $3"
					echo ---------------------------------
					;;
				strerr)	err_msg=$3;;
				warn)	c_red='\033[0;31m'; c_def='\033[0;m'; err_msg=$3;;
				fmt)	err_msg=$3; printf -v err_msg "$err_msg" "${@:4}";;
				error_t) ;;
				*)		error.__trace def; return $?;;
			esac
				
			echo -e "${c_red}${0##*/}: erro: linha ${line:-${BASH_LINENO[1]}}: ${func:-${FUNCNAME[2]}}: ${code:-$2}: ${err:-$err_msg} ${c_def}"
			exit ${code:-$2}
			;;
	esac
	
	return ${code:-$2}
}

function error.trace()
{
	getopt.parse -1 "flag:flag:+:$1" "argname:str:-:$2" "argtype:str:-:$3" "value:str:-:$4" "error:str:-:$5" "args:str:-:$6" ... "${@:7}"

	local i l t fn
	local stack

	[[ "${FUNCNAME[1]}" == "getopt.parse" ]] && fn=2 || fn=1

	t=(${FUNCNAME[@]:$fn})
	l=(${BASH_LINENO[@]:$fn})
	
	for ((i=${#t[@]}-1; i>=0; i--)); do
		stack+="[${l[$i]}:${t[$i]}] "
	done

	case $__ON_ERROR_RESUME in
		true)	
			__ERR__=${6:-1}
			__ERR_STACK__=${stack% }
			__ERR_ARG__=$2
			__ERR_TYPE__=$3
			__ERR_VAL__=$4
			__ERR_MSG__=${5:-erro desconhecido}
			__ERR_FUNC__=${FUNCNAME[$fn]}
			__ERR_LINE__=${BASH_LINENO[$fn]}
			;;
		false)
			exec 1>&2
			stack=${stack// / => }
			echo "(Pilha de rastreamento)"
			echo "Script: ${0##*/}"
			echo
			echo "Chamada interna: ${FUNCNAME[0]}"
			echo "Função: ${FUNCNAME[1]}"
			echo
			echo -e "Pilha: ${stack% => }"
	
			case $1 in
				imp)
					echo "Tipo: $3"
					echo "Método: $4"
					;;
				src)
					echo "Source: $3"
					echo "Tipo: [$4]"
					;;
				def)
					echo "Argumento: <$2>"
					echo "Tipo: [$3]"
					echo "Valor: '$4'"
					;;
				exa)
					echo "Argumento(s): '$4'"
					;;
				deps)
					echo "Source: $3"
					echo "Dependência(s): $4"
					;;
				st)
					echo "Estrutura: <$2>"
					echo "Membro: [$3]"
					echo "Tipo: $4"
				;;
			esac
		
			echo "Erro: ${5:-erro desconhecido}"
			echo "------------------------"
	
			exit 1
			;;
	esac	

	return 1
}

source.__INIT__
# /* __ERROR_SH */
