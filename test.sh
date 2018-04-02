#!/bin/bash

#IFS=$'\n'
catalogue=~
extension=sh
extension=$(echo "."$extension)

test_array=(dupa jasia pierdzi)
for i in "${test_array[@]}" 
do 
	echo $i 
done

array=()
while IFS= read -r; do
    array+=("$REPLY")
done < <(find $catalogue -name "*$extension")
printf '%s\n' "${array[@]}"