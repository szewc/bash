#!/bin/bash

IFS=$'\n'


function main() {
	paramaters
	modulo_operations
	generate_set
	factorial_standard
	factorial_plus
	modification_date
#	code_injection
	array_extension
	read_eof
	numbers_sorting
	array_associate
	array_length
	array_listing
}


function paramaters() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
for paramater in $@
do
	echo $paramater
done

temp="pretty nice day"
array=("$temp" 2 3)
for value in ${array[@]}
do
	echo $value
done
echo -e "********\nend of ${FUNCNAME[0]}"
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


function array_extension() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
test_array=(1 2 3)
echo "test array is:"
for i in "${test_array[@]}" 
do 
	echo $i 
done

catalogue=~
extension=sh
extension=$(echo "."$extension)
array=()
while IFS= read -r; do
    array+=("$REPLY")
done < <(find $catalogue -name "*$extension")
echo "files with extension $extension at $catalogue are:"
printf '%s\n' "${array[@]}"
echo -e "********\nend of ${FUNCNAME[0]}"
}


function read_eof() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
cat <<EOF
This will print using in-script EOF
test string 1
test string 2
EOF

# -r disables end of line
# -d sets end of file symbol
read -r -d '' reading < ./1.txt
echo "This will print contents of '1.txt'"
echo "$reading"

# usage of variables in EOF printing
# appending the string for variable
a="This is a"
read -r -d '' a <<EOF
$a
$(echo "test message.")
EOF
# not using "" would concatenate into single line
echo "$a"
echo -e "********\nend of ${FUNCNAME[0]}"
}


function numbers_sorting() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
array=(72 9299 37 92 37 82 0 3 47 32)
count=$(echo ${#array[@]})
echo "Number count is $count"
i=0
while [[ $i -lt $count ]] 
do
	j=$(($count - 1))
	min=""
	while [[ $j -ge $i ]]
	do
		if [[ -z $min || ${array[$j]} -lt ${array[$min]} ]]
			then
			min=$j
		fi
		((j--))
	done
	temp=${array[$i]}
	array[$i]=${array[$min]}
	array[$min]=$temp
	((i++))
done
echo "Sorted numbers are:"
echo "${array[@]}"
echo -e "********\nend of ${FUNCNAME[0]}"
}


function array_associate() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
# declare an array of associate type
# lets you index the values via strings/names
# not number indexes
declare -A data
data[type]="string"
data[value]="chair"
data[cost]="40"
echo ${data[value]}
echo ${data[@]}
echo -e "********\nend of ${FUNCNAME[0]}"
}


function array_length() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
array=("this" "is" "a" "test")
# even though we declare index 9
array[9]="car"
# array length will be 5 (start value + one additional)
echo -e "array length is " ${#array[@]}
# indexing starts at 0, so there is no value for [4]
echo -e "element with index [4] is "${array[4]}
# but [9] has been declared
echo -e "element with index [9] is "${array[9]}
echo -e "********\nend of ${FUNCNAME[0]}"
}


function array_listing() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
array=("this" "is" "a" "test")
array[7]="wine"
array[9]="car"
length=${#array[@]}

# arithmetic notation gets correct number of indexes, 
# but does not map them directly
# don't use unless your array is mapped continously
echo "arithmetic notation is"
for ((i=0; i<$length; i++))
do
	echo "element $i is: "${array[$i]}
done

# it's better to use collection notation
# when listing array elements
echo "notation based on collections is"
i=0
for element in ${array[@]}
do
	echo "element $i is: "$element
	((i++))
done
echo -e "********\nend of ${FUNCNAME[0]}"
}


function test() {
echo -e "beginning of ${FUNCNAME[0]}\n********"
echo -e "********\nend of ${FUNCNAME[0]}"
}


main