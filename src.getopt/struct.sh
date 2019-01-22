#!/bin/bash

#----------------------------------------------#
# Source:           struct.sh
# Data:             25 de dezembro de 2017
# Desenvolvido por: Juliano Santos [SHAMAN]
# E-mail:           shellscriptx@gmail.com
#----------------------------------------------#

[[ $__STRUCT_SH ]] && return 0

readonly __STRUCT_SH=1

source builtin.sh

readonly __ERR_STRUCT_ALREADY_INIT='a estrutura já foi inicializada'
readonly __ERR_STRUCT_NOT_MEMBER='não é um membro da estrutura'
readonly __ERR_STRUCT_MEMBER_NAME='nomenclatura do membro da estrutura é inválida'
readonly __ERR_STRUCT_MEMBER_CONFLICT='conflito de membros na estrutura'

# type struct
#
# Implementa 'S' com os métodos:
#
# S.add <[str]member> ...
# S.members => [str]
# S. <[str]member> => [str]
#
struct.add()
{
	getopt.parse "var:map:+:$1" "member:str:+:$2"
	
	builtin.__extfncall || return 1

	local __member
	local __parent=${FUNCNAME[2]}
	
	declare -n __byref=$1

	if [[ ${__byref[$__parent]} ]]; then
		error.__trace def 'member' 'str' "$2" "$__ERR_STRUCT_ALREADY_INIT"
		return $?
	fi
	
	for __member in ${@:2}; do
		if ! [[ $__member =~ ^[a-zA-Z0-9_.]+$ ]]; then
			error.__trace def 'member' 'str' "$__member" "$__ERR_STRUCT_MEMBER_NAME"
			return $?
		elif [[ ${__byref[$__parent.$__member]} ]]; then
			error.__trace def 'member' 'str' "$__member" "$__ERR_STRUCT_MEMBER_CONFLICT"
			return $?
		fi
		__byref[$__parent.$__member]=' '
		__STRUCT_REG_LIST[$__parent.$1]+="$__parent.$__member "
	done
	
	__byref[$__parent]=1
	__STRUCT_REG_LIST[$__parent.$1]+=$__parent

	return 0
}

struct.members()
{
	getopt.parse "var:map:+:$1"

	builtin.__extfncall || return 1

	local parent=${FUNCNAME[2]}
	local member

	for member in ${__STRUCT_REG_LIST[$parent.$1]}; do
		[[ $member != $parent ]] && echo "${member#$parent.}"
	done
	
	return 0
}

struct.(){
	getopt.parse "var:map:+:$1" "member:str:+:$2" 

	builtin.__extfncall || return 1

	local __parent=${FUNCNAME[2]}
	local __data

	declare -n __byref=$1
	
	if ! [[ ${__byref[$__parent.$2]} ]]; then
		error.__trace def 'member' 'str' "$2" "$__ERR_STRUCT_NOT_MEMBER"
		return $?
	fi

	if [[ $3 == = ]]; then
		__data=$4
		__byref[$__parent.$2]=${__data:- }
	else
		for __member in ${@:2}; do
			if ! [[ ${__byref[$__parent.$__member]} ]]; then
				error.__trace def 'member' 'str' "$__member" "$__ERR_STRUCT_NOT_MEMBER"
				return $?
			fi
			echo "${__byref[$__parent.$__member]}"
		done
	fi
			
	return 0	
}

readonly -f struct.add \
			struct.members \
			struct.

# /* __STRUCT_SH */
