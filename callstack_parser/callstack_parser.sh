#!/bin/bash

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#BACKTRACE="~/path/to/backtrace"
#PREFIX="(+0x"
#SUFFIX=")"
#OFFSET="0"
#SYMBOLS="/path/xxx.debug"
#SYMBOLS_PACKAGE="~/path/to/xxx-debug-symbols"
#CORE="/path/to/core-dump"


IFS=$'\n'
set -f


help_info() {
cat << EOF
Program can be run in interacive mode (default), with the usage of select run options, or any combination of the above.

usage: 
callstack_parser.sh 
	-b, --backtrace "/path/log.txt" 
	-p, --prefix "abc"
	-s, --suffix "def"
	-o, --offset "08ab"
	-m, --symbols "/path/file.debug"
		// or "/path/unstripped.lib"
	-y, --symbols-package "/path/xxx-debug-symbols"
	-c, --core "/path/to/core_dump"
	-h, --help

example 1:
#interactive mode
./callstack_parser.sh

example 2: 
./callstack_parser.sh --backtrace "~/log/backtrace.txt" -p "(+a" --symbols-package "~/random/xxx-debug-symbols.tgz"

example 3: 
// symbols for single lib only
./callstack_parser.sh -m "/path/to/738a252ff76faa795ce57a86f5852b8c.debug"
// or unstripped library
./callstack_parser.sh -m "/path/to/unstripped.lib" -b "~/log/backtrace.txt" -p "(+a"


Repository is https://github.com/szewc/bash/callstack_parser/
EOF
exit 1;
}

main() {
deps_check_addr2line
deps_check_cfilt
deps_check_dialog
backtrace_select
translate_finish
}


deps_check_addr2line() {
which addr2line > /dev/null 2>&1
INSTALLED=$?
if [ $INSTALLED -eq 1 ]; then
        echo "addr2line is not installed"
	echo "Install it from official repo?"
	select yn in "Yes" "No"; do
		case $yn in
                Yes ) deps_install; break;;
                No ) exit;;
		esac
	done
fi
}


deps_check_cfilt() {
which c++filt > /dev/null 2>&1
INSTALLED=$?
if [ $INSTALLED -eq 1 ]; then
        echo "c++filt is not installed"
	echo "Install it from official repo?"
	select yn in "Yes" "No"; do
		case $yn in
                Yes ) deps_install; break;;
                No ) exit;;
		esac
	done
fi
}


deps_check_dialog() {
which dialog > /dev/null 2>&1
INSTALLED=$?
if [ $INSTALLED -eq 1 ]; then
	echo "dialog is not installed"
	echo "Install it from official repo?"
	select yn in "Yes" "No"; do
		case $yn in
                Yes ) deps_install; break;;
                No ) exit;;
		esac
	done
fi
}


deps_install() {
if [ "$EUID" -ne 0 ]
	then echo "To install the dependencies please run as root" >&2
	exit
fi
	apt install -y --no-install-recommends binutils
	apt install -y --no-install-recommends dialog
echo "Installed the deps, please re-run the script. Sudo is not required."
exit
}


backtrace_select() {
# select backtrace
# store it to $BACKTRACE if no $BACKTRACE is set
eval BACKTRACE=$BACKTRACE
if [ ! -z "$BACKTRACE" ]; then 
	if [ ! -f "$BACKTRACE" ]; then
		echo $BACKTRACE" - file not found. Exiting."
		exit 1
	fi
	echo "BACKTRACE set is "$BACKTRACE
	core_evaluate
	symbols_select
	translate_file
else
    echo "How do you want to input backtrace log?"
    select option in "Paste log contents" "Provide path to log" "Select the log file via file manager"; do
        case $option in
            "Paste log contents" ) backtrace_store_contents; break;;
            "Provide path to log" ) backtrace_store_path; break;;
			"Select the log file via file manager" ) backtrace_store_manager; break;;
			*) echo "invalid option";;
        esac
	done
fi
}


backtrace_store_contents() {
echo "Follow the instructions:
1. Paste the log contents
2. To store the last line press [ENTER]
3. Terminate the input with [CTRL-D]"
BACKTRACE=$(</dev/stdin)
echo "-----------"
echo "Contents loaded"
core_evaluate
prefix_store
let is_backtrace_contents=1
prefix_suffix_evaluate_contents
symbols_select
translate_contents
}


backtrace_store_path() {
echo "Provide (paste or input by hand with autocomplete) the path to text file with backtrace,"
echo "confirm with [ENTER]"
read -e BACKTRACE
eval BACKTRACE=$BACKTRACE
	if [ ! -e "$BACKTRACE" ]
		then
		echo "File not found"
		exit
	fi
core_evaluate
prefix_store
let is_backtrace_file=1
prefix_suffix_evaluate_file
symbols_select
translate_file
}


backtrace_store_manager() {
BACKTRACE=$(dialog --stdout --title "Select the text file with backtrace" --fselect $PWD 14 50)
	if [ ! -e "$BACKTRACE" ]
		then
		dialog --title "File not found" --clear --msgbox "$m" 10 50
		exit
	fi
core_evaluate
prefix_store
let is_backtrace_file=1
prefix_suffix_evaluate_file
symbols_select
translate_file
}


core_evaluate() {
eval CORE=$CORE
if [ ! -z "$CORE" ]; then 
	echo "CORE set is "$CORE
	let core_is_file=1
	prefix_store
	symbols_select
	translate_file
elif [ ! -z "$OFFSET" ]; then
	prefix_store
else
	echo "Do you want to load core dump file?"
	echo "It will be used to get offset values"
	select option in "No" "Yes"; do
	        case $option in
	        	"No" ) prefix_store; break;;
	        	"Yes" ) core_select; break;;
	            *) echo "invalid option";;
	        esac
	done
fi
}


core_select() {
# select core dump file
# store it to $CORE
echo "File has to be plain text, in a format '* memory_map * permission_bit * lib_name *' eg.:"
echo -e "\n[dtv_app_mtk]>b343f000-b3440000 rw-p 0001d000 fe:03 11826      /3rd/browser_engine/libuvamse.so\n"
echo "How do you want to load core dump file?"
select option in "Paste core contents" "Provide path to file" "Select file via file manager"; do
    case $option in
    	"Paste core contents" ) core_store_contents; break;;
        "Provide path to file" ) core_store_path; break;;
		"Select file via file manager" ) core_store_manager; break;;
		*) echo "invalid option";;
    esac
done
}


core_store_contents() {
echo "Follow the instructions:
1. Paste the contents
2. To store the last line press [ENTER]
3. Terminate the input with [CTRL-D]"
CORE=$(</dev/stdin)
echo "-----------"
echo "Contents loaded"
let is_core_contents=1
prefix_store
if [[ is_backtrace_contents == 1 ]]; then
	prefix_suffix_evaluate_contents
else 
	prefix_suffix_evaluate_file
fi
symbols_select
translate_contents
}


core_store_path() {
echo "Provide (paste or input by hand with autocomplete) the path to the core dump file."
echo "Confirm with [ENTER]"
read -e CORE
eval CORE=$CORE
if [ ! -e "$CORE" ]
	then
	echo "File not found"
	exit
else
	is_core_file=1
fi
prefix_store
if [[ is_backtrace_contents == 1 ]]; then
	prefix_suffix_evaluate_contents
else 
	prefix_suffix_evaluate_file
fi
symbols_select
translate_file
}


core_store_manager() {
CORE=$(dialog --stdout --title "Select the core dump file" --fselect $PWD 14 50)
if [ ! -e "$CORE" ]
	then
	dialog --title "File not found" --clear --msgbox "$m" 10 50
	exit
else 
	let is_core_file=1
fi
prefix_store
if [[ is_backtrace_contents == 1 ]]; then
	prefix_suffix_evaluate_contents
else 
	prefix_suffix_evaluate_file
fi
symbols_select
translate_file
}


prefix_store() {
# select address prefix using default or user input
if [ -z $PREFIX ]; then 
echo "Select the prefix for the addresses to be recognized by."
echo "For example if the addresses are presented starting with '0x', it should be input as prefix."
select option in "Use default prefix (+0x" "Input prefix"; do
	case $option in
                "Use default prefix (+0x" ) 
			PREFIX="(+0x";
			break;;
                "Input prefix" ) 
			echo "Input the prefix, special characters are allowed";
			read -p "PREFIX should be " -e PREFIX;
			break;;
		*) echo "invalid option";;
        esac
	done
fi
# properly escape [ and ]
PREFIX=$(echo "$PREFIX" | sed 's/\[/\\\[/')
echo "PREFIX set is "$PREFIX
suffix_store
}

suffix_store() {
# select address suffix using default or user input
if [ -z $SUFFIX ]; then 
echo "Select the suffix for the addresses to be recognized by"
select option in "Use default suffix )" "Input suffix"; do
	case $option in
                "Use default suffix )" )
			SUFFIX=")";
			break;;
                "Input suffix" ) 
			echo "Input the suffix, special characters are allowed"
			read -p "SUFFIX should be " -e SUFFIX
			break;;
		*) echo "invalid option";;
        esac
	done
fi
# properly escape [ and ]
SUFFIX=$(echo "$SUFFIX" | sed 's/\]/\\\]/')
echo "SUFFIX set is ""$SUFFIX"
offset_evaluate
}


offset_evaluate() {
if [[ -z $OFFSET && -z $CORE || "$offset_invalid" = 1 ]]; then
	offset_store
elif [[ ! -z $OFFSET && ! -z $(echo "$OFFSET" | grep -o '\b0\x') ]]; then
	echo "You did attempt to set OFFSET as ""$OFFSET"

	echo "Do not use a leading value like 0x for OFFSET"
	sleep 2
	offset_store
elif [[ ! -z $CORE ]]; then
	echo "OFFSET values will be loaded from CORE"
else
	echo "OFFSET set is ""$OFFSET"
fi
}


offset_store() {
# select address offset using default or user input
echo "(OPTIONAL) Select the memory mapping offset for the addresses"
echo "This is single value mode only. To dynamically load offset values, load the core dump file."
echo "Select option 1. (default, offset=0) if you don't want to calculate it."
select option in "Use default offset 0" "Input offset"; do
	case $option in
                "Use default offset 0" )
			OFFSET="0";
			break;;
                "Input offset" ) 
			echo "Input the offset value, in hexadecimal notation."
			echo "Example offset: 0c3a9"
			echo "Do not use a leading value like '0x'. Case sensitive."
			echo "Offset value will be subtracted from the address value."
			read -p "OFFSET should be " -e OFFSET
			if [ ! -z $(echo "$OFFSET" | grep -o '\b0\x') ]; then
				let offset_invalid=1
				echo "Do not use a leading value like 0x"
				sleep 2
				offset_evaluate
			else
				echo "OFFSET set is ""$OFFSET"
			fi
			break;;
		* ) echo "invalid option";;
	esac
done
}


prefix_suffix_evaluate_contents() {
p=$(echo "$BACKTRACE" | grep -o "$PREFIX[a-zA-Z0-9]\+$SUFFIX")
test "$p" 
if [ $? != 0 ] ; then 
	if [ -z $(echo "$BACKTRACE" | grep "_Z[a-zA-Z0-9_+]\+$SUFFIX") ]; then
		echo "No addresses with both PREFIX "$PREFIX" and SUFFIX "$SUFFIX","
 		echo "as well as no mangled symbols have been found. Exiting."
		exit
	else
		echo "No addresses with both PREFIX "$PREFIX" and SUFFIX "$SUFFIX" have been found,"
		echo "but at least one mangled symbol has been found."
		let MANGLED=1
	fi
else
	echo "At least one address with both PREFIX "$PREFIX" and SUFFIX "$SUFFIX" has been found." 
fi
}


prefix_suffix_evaluate_file() {
p=$(grep -o "$PREFIX[a-zA-Z0-9]\+$SUFFIX" < $BACKTRACE)
test "$p" 
if [ $? != 0 ] ; then 
	if [ -z $(grep "_Z[a-zA-Z0-9_+]\+$SUFFIX" < $BACKTRACE) ]; then
		echo "No addresses with both PREFIX "$PREFIX" and SUFFIX "$SUFFIX","
 		echo "as well as no mangled symbols have been found. Exiting."
		exit
	else
		echo "No addresses with both PREFIX "$PREFIX" and SUFFIX "$SUFFIX" have been found,"
		echo "but at least one mangled symbol has been found."
		let MANGLED=1
	fi
else
	echo "At least one address with both PREFIX "$PREFIX" and SUFFIX "$SUFFIX" has been found." 
fi
}


symbols_select() {
if [ "$MANGLED" = 1 ]; then
	:
else 
	# if no $SYMBOLS_PACKAGE is set select
	eval SYMBOLS=$SYMBOLS
	eval SYMBOLS_PACKAGE=$SYMBOLS_PACKAGE
	if [ ! -z "$SYMBOLS" ] || [ ! -z "$SYMBOLS_PACKAGE" ]; then
		symbols_evaluate
	else
		echo "How do you want to load debug symbols?"
		echo "Debug package chosen can be compressed"
		echo "Note: symbols will be loaded automatically for every recognized library in the backtrace log"
		select option in "Provide path to debug package" "Select the debug package via file manager"; do
		    case $option in
		        "Provide path to debug package" ) symbols_store_path; break;;
			"Select the debug package via file manager" ) symbols_store_manager; break;;
			*) echo "invalid option";;
		    esac
		done
	symbols_evaluate
	fi
fi
}


symbols_store_path() {
# store it to $SYMBOLS_PACKAGE
echo "Provide (paste or input by hand with autocomplete) the path to the debug package,"
echo "eg. /path/to/xxx-debug-symbols[.tar.gz]"
echo "confirm with [ENTER]"
read -e SYMBOLS_PACKAGE
eval SYMBOLS_PACKAGE=$SYMBOLS_PACKAGE
	if [ ! -e $SYMBOLS_PACKAGE ]; then
		echo "Not found"
		exit
	fi
}


symbols_store_manager() {
# select filename using dialog
# store it to $SYMBOLS_PACKAGE
SYMBOLS_PACKAGE=$(dialog --stdout --title "Select the folder or file with debug symbols" --fselect $PWD 14 50)
	if [ ! -e "$SYMBOLS_PACKAGE" ]; then
		dialog --title "Not found" --clear --msgbox "$m" 10 50
		exit
	fi
}


symbols_evaluate() {
# find main addressing file and available libs
if [ ! -z "$SYMBOLS" ]; then
	echo "SYMBOLS .debug file set manually is "$SYMBOLS
	echo "This file will be used for all of the provided addresses"
	let is_symbols_set=1
# extract the debug symbols package
elif [[ $SYMBOLS_PACKAGE =~ \.t?gz$ ]]; then
	FILE=$(basename $SYMBOLS_PACKAGE)
	echo "File "$FILE" is compressed as .tar.gz / .tgz"
	echo "Do you want to extract it at "$(dirname $SYMBOLS_PACKAGE)" (default)?"
	select yn in "Yes" "No"; do
	    case $yn in
	        Yes ) 
			cd $(dirname $SYMBOLS_PACKAGE) &> /dev/null
			SYMBOLS_PACKAGE=$(sed 's/\.ta*r*\.*gz$//' <(echo $SYMBOLS_PACKAGE))
			mkdir $SYMBOLS_PACKAGE
			echo "Extracting files..."
			tar -zxvf $FILE -C $SYMBOLS_PACKAGE
			sync
			echo "Done extracting"
			cd - &> /dev/null
			echo "SYMBOLS_PACKAGE set is "$SYMBOLS_PACKAGE
			CONTENTS=$(find $SYMBOLS_PACKAGE -name *contents)
			echo "Main addressing file is "$CONTENTS
			LIBS=$(cat $CONTENTS | grep -o -P '[\S]*.sym$' | sed 's/\.sym//')
			echo "Listed LIBS with available symbols are: "$LIBS
			break;;
	        No ) 
			echo "Program requires an extracted package, exiting."
			exit;;
	    esac
	done
else	
	if [ ! -d "$SYMBOLS_PACKAGE" ]; then
		echo $SYMBOLS_PACKAGE" is not a directory or .tar.gz / .tgz package"
		exit
	fi
	echo "SYMBOLS_PACKAGE set is "$SYMBOLS_PACKAGE
	CONTENTS=$(find $SYMBOLS_PACKAGE -name *contents)
	echo "Main addressing file is "$CONTENTS
	LIBS=$(cat $CONTENTS | grep -o -P '[\S]*.sym$' | sed 's/\.sym//')
	echo "Listed LIBS with available symbols are: "$LIBS
fi
}


translate() {
echo "----------"
LIB=$(echo $i | grep -o "$LIBS")
if [ -z "$LIB" ]; then
	if [[ $is_symbols_set = 1 ]]; then
		# beginning of translate from single file
		a=$((a + 1))
		echo "Operation no. "$a
		j=$(echo $i | grep -o "$PREFIX[a-zA-Z0-9]\+" | sed "s/$PREFIX//")
		# applying OFFSET from CORE
		if [[ ! -z $CORE && $is_core_contents = 1 ]]; then
			OFFSET=$(echo "$CORE" | grep -o -E ".*r-xp.*${LIB}.*" | grep -o -P '[0-9A-Za-z-]* r-xp' | sed 's/-.*$//')
		elif [[ ! -z $CORE && $is_core_file = 1 ]]; then
			OFFSET=$(grep -o -E ".*r-xp.*${LIB}.*" < $CORE | grep -o -P '[0-9A-Za-z-]* r-xp' | sed 's/-.*$//')
		fi
		# calculating absolute value of the offset (from core or if set by hand)
		if [[ "$OFFSET" != 0 ]]; then
			OFFSET=${OFFSET#-}
		fi
		# applying offset
		l=$(printf "%x\n" $((0x$j-0x$OFFSET)))
		echo "Translating address "$l
		addr2line -fsp  -e $SYMBOLS -a $l | c++filt >> stack.out
		# end of translate from single file
	elif [ -z $(echo $i | grep -o '[A-Za-z\.\_\-]\+\.so') ]; then
		echo "There is no recognized library for line"
		echo $i
	elif [ -z $(echo $i | grep -o '[A-Za-z\.\_\-]\+\.so' | grep "$LIBS") ]; then
		echo $(echo $i | grep -o '[A-Za-z\.\-]\+\.so')" is not recognized library or has no symbols"
	else
		echo "Library "$(echo $i | grep -o '[A-Za-z\.\_\-]\+\.so')" has no debug symbols"
	fi
else
	a=$((a + 1))
	echo "Operation no. "$a
	echo "Recognized library is "$LIB
	SYMBOLS="$SYMBOLS_PACKAGE/$(cat $CONTENTS | grep $LIB | awk '{print $1}')"
	echo "Its debug symbols are at "$SYMBOLS
	j=$(echo $i | grep -o "$PREFIX[a-zA-Z0-9]\+" | sed "s/$PREFIX//")
	# applying OFFSET from CORE
	if [[ ! -z $CORE && $is_core_contents = 1 ]]; then
		OFFSET=$(echo "$CORE" | grep -o -E ".*r-xp.*${LIB}.*" | grep -o -P '[0-9A-Za-z-]* r-xp' | sed 's/-.*$//')
	elif [[ ! -z $CORE && $is_core_file = 1 ]]; then
		OFFSET=$(grep -o -E ".*r-xp.*${LIB}.*" < $CORE | grep -o -P '[0-9A-Za-z-]* r-xp' | sed 's/-.*$//')
	fi
	# calculating absolute value of the offset (from core or if set by hand)
	if [[ "$OFFSET" != 0 ]]; then
		OFFSET=${OFFSET#-}
	fi
	# applying offset
	l=$(printf "%x\n" $((0x$j-0x$OFFSET)))
	echo "Translating address "$l
	addr2line -fsp  -e $SYMBOLS -a $l | c++filt >> stack.out
fi
}


translate_mangled() {
echo "----------"
a=$((a + 1))
echo "Operation no. "$a
echo "Demangling symbols "$k
echo "$k" | c++filt >> stack.out
}


translate_contents() {
# recognize the address, select appropriate lib, load its symbols and translate
# this methoud uses pasted backtrace
core_is_contents=1
[ -f ./stack.out ] && rm ./stack.out && echo "Removing old ./stack.out..."
a=0
for LOOP in $(echo "$BACKTRACE" | grep "[a-zA-Z0-9\-\_\+]\+$SUFFIX"); do
	for i in $(echo "$LOOP" | grep "$PREFIX[a-zA-Z0-9]\+$SUFFIX"); do
		translate
	done
	for k in $(echo "$LOOP" | grep -o "_Z[a-zA-Z0-9\-\_\+]\+$SUFFIX" | sed -e "s/$SUFFIX$//"); do
		translate_mangled
	done
done
}


translate_file() {
# recognize the address, select appropriate lib, load its symbols and translate
# this methoud uses backtrace file
[ -f ./stack.out ] && rm ./stack.out && echo "Removing old ./stack.out..."
a=0
for LOOP in $(grep "[a-zA-Z0-9\-\_\+]\+$SUFFIX" < $BACKTRACE); do
	for i in $(echo "$LOOP" | grep "$PREFIX[a-zA-Z0-9]\+$SUFFIX"); do
		translate
	done
	for k in $(echo "$LOOP" | grep -o "_Z[a-zA-Z0-9\-\_\+]\+$SUFFIX" | sed -e "s/$SUFFIX$//"); do
		translate_mangled
	done
done
}


translate_finish() {
if [ ! -z "$l" ]; then
	echo -e "----------\nDone\nTranslated stack trace is\n**********\n$(cat ./stack.out)\n**********\nIt has also been saved to ./stack.out"
elif [ "$MANGLED" = 1 ]; then
	echo -e "----------\nDone\nTranslated stack trace is\n**********\n$(cat ./stack.out)\n**********\nIt has also been saved to ./stack.out"
else
	echo "No valid addresses found in the backtrace."
fi
}


OPTS=$(getopt -o b:p:s:o:m:y:c:h --long backtrace:,prefix:,suffix:,offset:,symbols:,symbols-package:,core:,help -n 'callstack_parser.sh' -- "$@")
if [ $? != 0 ] ; then help_info ; exit 1 ; fi
	eval set -- "$OPTS"
while true; do
        case "$1" in
		-b | --backtrace ) BACKTRACE="$2"; shift 2;;
		-p | --prefix ) PREFIX="$2"; shift 2;;
		-s | --suffix ) SUFFIX="$2"; shift 2;;
		-o | --offset ) OFFSET="$2"; shift 2;;
		-m | --symbols ) SYMBOLS="$2"; shift 2;;
		-y | --symbols-package ) SYMBOLS_PACKAGE="$2"; shift 2;;
		-c | --core ) CORE="$2"; shift 2;;
		-h | --help ) help_info; break;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done


main "${@}"