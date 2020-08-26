#!/bin/bash
IFS=$'\n'

# CHECK IF KUBECTL IS INSTALLED
kubectl version > /dev/null
if [[ $? -ne 0 ]] ; then
	echo "kubectl is not installed! Aborting..."
	exit 1
fi

# OUTPUT FILES
OUTPUT_FOUND="images-found.txt"
OUTPUT_NOT_FOUND="images-not-found.txt"
OUTPUT_TO_CHECK="TO_CHECK.txt"

# OUTPUT ARRAYS
FOUND=("FOLLOWING PODS HAS ONLY ONE IMAGE WITH RECOGNIZED OS VERSION:")
NOT_FOUND=("FOLLOWING PODS DOES NOT CONTAINT /etc/lsv-release FILE - CAN'T REGOGNIZE BASE IMAGE OS")
TO_CHECK=("FOLLOWING PODS SHOULD BE CHECKED MANUALLY (MORE THAN ONE CONTAINER)")

# ITERATE OVER NAMESPACES
for NAMESPACE in $(kubectl get namespaces | awk '{print $1}') ; do
	
	#skip first line
	if [[ $c1 -eq 0 ]] ; then ((c1++)) ; continue ; fi

	# print namespace header
	echo -e "\e[33m\nNAMESPACE: $NAMESPACE\e[0m"
	
	# ITERATE OVER PODS IN NAMESPACE
	for POD in $(kubectl get pods -n $NAMESPACE | awk '{print $1}') ; do
		# skip first line
		if [[ $c2 -eq 0 ]] ; then ((c2++)) ; continue ; fi

		# GET OS INFO
		OS_INFO=$(kubectl exec $POD -n $NAMESPACE -- cat /etc/lsb-release 2> /dev/null )	
		
		# PARSE OS DETAILS MESSAGE	
		if [[ $OS_INFO =~ "DISTRIB_DESCRIPTION=" ]] ; then
			OS_INFO="${OS_INFO##*$'\n'}"
			
			# get image from current pod
			IMAGE=$(kubectl describe pod $POD -n $NAMESPACE | grep "Image:" | awk '{print $2}')
			if [[ $(echo $IMAGE | wc -w) -gt 1 ]] ; then 
				echo -e "\e[31mMULTIPLE CONTAINERS FOUND IN POD: $POD (NAMESPACE: $NAMESPACE) - MANUAL VERIFICATION NEEDED\e[0m"
			        TO_CHECK+=("$POD (namespace: $NAMESPACE)")
				continue;
			fi
			echo -e "\e[32m$POD - $(echo "$OS_INFO " | cut -c 21-)- $IMAGE \e[0m"
			FOUND+=("$IMAGE = $OS_INFO")
		else 
			echo -ne "$POD - "
			echo "NO OS INFO FOUND"
			NOT_FOUND+=("$POD (namespace: $NAMESPACE)")
		fi
	done
	c2=0	#reset line skipping counter2
done

# CLEAR OUTPUT FILES
echo -n "" > $OUTPUT_FOUND
echo -n "" > $OUTPUT_NOT_FOUND
echo -n "" > $OUTPUT_TO_CHECK

# SAVE RESULTS TO FILE
for line in "${FOUND[@]}" ; do
	echo $line >> $OUTPUT_FOUND;
done

for line in "${NOT_FOUND[@]}" ; do
        echo $line >> $OUTPUT_NOT_FOUND;
done

for line in "${TO_CHECK[@]}" ; do
        echo $line >> $OUTPUT_TO_CHECK;
done

echo "removing duplicates..."

# REMOVE DUPLICATES
cat $OUTPUT_FOUND | uniq > of.tmp
mv of.tmp $OUTPUT_FOUND
TMP=$(wc -l $OUTPUT_FOUND | awk '{print $1}')
((TMP--))
echo "$TMP unique images were checked successfully" 

cat $OUTPUT_NOT_FOUND | uniq > onf.tmp
mv onf.tmp $OUTPUT_NOT_FOUND
TMP=$(wc -l $OUTPUT_NOT_FOUND | awk '{print $1}')
((TMP--))
echo "$TMP images couldn't be checked"


cat $OUTPUT_TO_CHECK | uniq > tc.tmp
mv tc.tmp $OUTPUT_TO_CHECK
TMP=$(wc -l $OUTPUT_TO_CHECK | awk '{print $1}')
((TMP--))
echo "$TMP pods needs to be checked manually"


echo "done."
