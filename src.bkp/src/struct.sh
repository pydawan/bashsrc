#!/bin/bash

[[ $__STRUCT_SH ]] && return 0

readonly __STRUCT_SH=1

source builtin.sh

declare -A  __STRUCT_VAL_MEMBERS \
			__STRUCT_MEMBER_TYPE \
			__INIT_STRUCT

readonly __ERR_STRUCT_MEMBER_NAME='nome do membro da estrutura inválido'
readonly __ERR_STRUCT_ALREADY_INIT='a estrutura já foi inicializada'
readonly __ERR_STRUCT_MEMBER_CONFLICT='conflito de membros na estrutura'
readonly __ERR_STRUCT_TYPE='requer estrutura do tipo'
readonly __ERR_STRUCT_NOT_FOUND='nome da estrutura inválida'
readonly __ERR_STRUCT_MEM_TYPE='tipo do membro do inválido'
readonly __ERR_STRUCT_MEM_TYPE_REQUIRED='tipo do membro da estrutura requerido'

__TYPE__[struct_t]='
struct.__add__
struct.__members__
struct.__len__
__type__
'

# func struct.__add__ <[struct_t]name> <[str]member> ...
#
# Adiciona 'N' membros a estrutura 'name'.
#
function struct.__add__(){
	getopt.parse -1 "name:struct_t:+:$1" "member:st_member:+:$2" ... "${@:3}"

	local struct=$1
	local mem

	if [[ ${__INIT_STRUCT[$struct]} ]]; then
		error.__trace st "$struct" '' '' "$__ERR_STRUCT_ALREADY_INIT"
		return $?
	fi

	set "${@:2}"

	while [[ ${#@} -gt 0 ]]; do
		if ! [[ $2 ]]; then
			error.__trace def "$struct" "$1" '' "$__ERR_STRUCT_MEM_TYPE_REQUIRED"
			return $?
		elif [[ ${__INIT_OBJ_TYPE[$2]} == struct_t ]]; then
			for mem in $($2.__members__); do
				if [[ ${__STRUCT_MEMBER_TYPE[$struct.$1.$mem]} ]]; then
					error.__trace st "$struct" "$1" "$2" "$__ERR_STRUCT_MEMBER_CONFLICT"
					return $?
				fi
				__INIT_SRC_TYPES[$struct]+="$struct.$1.$mem "
				__STRUCT_MEMBER_TYPE[$struct.$1.$mem]=${__STRUCT_MEMBER_TYPE[$2.$mem]}
			done
		else
			if ! [[ ${__HASH_TYPE[$2]} ]]; then
				error.__trace st "$struct" "$1" "$2" "$__ERR_STRUCT_MEM_TYPE"
				return $?
			elif [[ ${__STRUCT_MEMBER_TYPE[$struct.$1]} ]]; then
				error.__trace st "$struct" "$1" "$2" "$__ERR_STRUCT_MEMBER_CONFLICT"
				return $?
			fi
			__INIT_SRC_TYPES[$struct]+="$struct.$1 "
			__STRUCT_MEMBER_TYPE[$struct.$1]=$2
		fi
		shift 2
	done	

	__INIT_STRUCT[$struct]=true
	
	return 0
}

# func struct.__members__ <[struct_t]name> => [str]
#
# Lista os membros da estrutura.
#
function struct.__members__()
{
	getopt.parse 1 "name:struct_t:+:$1" "${@:2}"
	local mem
	for mem in ${__INIT_SRC_TYPES[$1]}; do
		echo "${mem#*.}"
	done
	return 0
}

# func struct.__len__ <[struct_t]name> => [uint]
#
# Retorna o total de elementos contidos na estrutura.
#
function struct.__len__()
{
	getopt.parse 1 "name:struct_t:+:$1" "${@:2}"

	local len=(${__INIT_SRC_TYPES[$1]})
	echo ${#len[@]}

	return 0	
}

source.__INIT__
# /* __STRUCT_SH */
