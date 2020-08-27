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

# OUTPUT ARRAYS
FOUND=("FOLLOWING PODS HAS ONLY ONE IMAGE WITH RECOGNIZED OS VERSION:")
NOT_FOUND=("FOLLOWING PODS DOES NOT CONTAINT /etc/lsv-release FILE - CAN'T REGOGNIZE BASE IMAGE OS")

# ITERATE OVER NAMESPACES
for NAMESPACE in $(kubectl get namespaces | awk '{print $1}' | tail -n +2) ; do

	# print namespace header
	echo -e "\e[33m\nNAMESPACE: $NAMESPACE\e[0m"
	
	# ITERATE OVER PODS IN NAMESPACE
	for POD in $(kubectl get pods -n $NAMESPACE | awk '{print $1}' | tail -n +2) ; do	
		echo -e "\nPOD: $POD"

		# ITERATE OVER POD'S CONTAINERS

		for CONT in $(kubectl get pods $POD -n $NAMESPACE -o jsonpath={.spec.containers[*].name}) ; do
			echo CONTAINER: $CONT
			# GET OS INFO
                	OS_INFO=$(kubectl exec $POD -c $CONT -n $NAMESPACE -- cat /etc/lsb-release 2> /dev/null )

			# PARSE OS DETAILS MESSAGE      
               		if [[ $OS_INFO =~ "DISTRIB_DESCRIPTION=" ]] ; then
                        	OS_INFO="${OS_INFO##*$'\n'}"
                        
                		# get image from current pod
                    		IMAGE=$(kubectl describe pod $POD -n $NAMESPACE | sed -n "/^\s*$CONT:$/,"'$p' | sed -n -e 's/^.*Image:\s*//p')
                        	
                       		echo -e "\e[32m$POD - $(echo "$OS_INFO " | cut -c 21-)- $IMAGE \e[0m"
                       	 	FOUND+=("$IMAGE = $OS_INFO")
                	
			else 
                        	echo -n "$POD - "
                        	echo "NO OS INFO FOUND"
                        	NOT_FOUND+=("$POD (namespace: $NAMESPACE)")
                	fi	
		done
	done
done


echo "saving output to file"

# CLEAR OUTPUT FILES
echo -n "" > $OUTPUT_FOUND
echo -n "" > $OUTPUT_NOT_FOUND



# SAVE RESULTS TO FILE
for line in "${FOUND[@]}" ; do
	echo $line >> $OUTPUT_FOUND;
done

for line in "${NOT_FOUND[@]}" ; do
        echo $line >> $OUTPUT_NOT_FOUND;
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


echo "done."
