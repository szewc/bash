#!/bin/bash

IFS=$'\n'


function main() {
	modulo_operations
	generate_set
	factorial_standard
	factorial_plus
	modification_date
	code_injection
}


function modulo_operations() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
a=7
declare -i rest
rest=$a%2

if [[ $rest == 0 ]]; then
	echo "even"
else
	echo "non-even"
fi
echo -e "********\nend of ${FUNCNAME[0]}"
}


function generate_set() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
min=3
#echo "input min for set"
#read min
max=45
#echo "input max for set"
#read max
modulo=4
#echo "input modulo for set"
#read modulo
echo "result for modulo in set of numbers is:"
i=$min
while [[ $i -le $max ]]; do 
	rest=$(( $i % $modulo ))
	if [[ $rest == 0 ]]; then
		echo $i
	fi
	i=$(($i+1))
done
echo -e "********\nend of ${FUNCNAME[0]}"
}


function factorial_standard() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
factorial_of=4
result=1
i=1
while (( $i <= $factorial_of ))
do
	result=$(( $result * $i ))
	i=$(($i + 1 ))
done
echo "factorial for given number is "$result
echo -e "********\nend of ${FUNCNAME[0]}"
}


function factorial_plus() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
factorial_of=5
result=1
i=1
for (( i = 1; i <= $factorial_of; i++ )); do
	result=$(( $result * $i ))
done
echo "factorial for given number is "$result
echo -e "********\nend of ${FUNCNAME[0]}"
}


function modification_date() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
# list files from x 
# that have been modified not later than y days ago
catalogue=~
extension=sh
extension=$(echo "."$extension)

path=()
while IFS= read -r; do
    path+=("$REPLY")
done < <(find $catalogue -name "*$extension")

days=3
seconds=$(($days * 86400))
minTime=$(date +"%s")
minTime=$(($minTime - $seconds))
for file in "${path[@]}"; do
	time=$(stat -c "%X" $file)
	if (( $time >= $minTime )); then
		time=$(stat -c "%y" $file)
		echo "file" $file "has modification time of: "$time" which is within given "$days" days"
		echo "-----"
	fi
done
echo -e "********\nend of ${FUNCNAME[0]}"
}


function code_injection() {
# defend against code injection when using the eval
echo -e "beginning of ${FUNCNAME[0]}\n********"
a="abba"
b="babba"
echo "Choose which variable to print [a/b]"
read name
if [[ $name == "a" || $name == "b" ]]; then
	echo -e "attempting to echo the variable value\nusing eval operation"
	eval "echo $"$name
else
	echo "code injection attempt has been spotted"
fi
echo -e "********\nend of ${FUNCNAME[0]}"
}


function test() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
echo -e "********\nend of ${FUNCNAME[0]}"
}


main