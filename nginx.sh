#!/bin/bash

# Usage: nginx_ingress_image_sync.sh [run_type] [license_cert] [license_key] [acr_name] [acr_fqdn] [acr_sub_name] [dry_run]

run_type="$1"

if [ "$run_type" == "data" ]; then 
	eval "$(jq -r '@sh "LICENSE_CERT=\(.license_cert) LICENSE_KEY=\(.license_key) ACR_NAME=\(.acr_name) ACR_FQDN=\(.acr_fqdn) ACR_SUB_NAME=\(.acr_sub_name) DRY_RUN=\(.dry_run)"')"
elif [ "$run_type" == "cli" ]; then
	LICENSE_CERT="`echo $2 | base64 -d`"
	LICENSE_KEY="`echo $3 | base64 -d`"
	ACR_NAME="$4"
	ACR_FQDN="$5"
	ACR_SUB_NAME="$6"
	DRY_RUN="$7"
else
	echo "Invalid run type"
	exit 1
fi

lock_file="/tmp/nginx_ingress_image_sync.lock"

if [ ! -f $lock_file ]; then
	touch $lock_file
fi

exec 100>$lock_file
flock -w 60 -x 100

if [ $? -ne 0 ]; then
	>&2 echo "Could not obtain the lock"
	exit 1
fi

# If the Nginx private repo directory doesn't exist, create it
if [ ! -d /etc/docker/certs.d/private-registry.nginx.com ]; then
	sudo mkdir -p /etc/docker/certs.d/private-registry.nginx.com
fi

# Put the license cert and key in the directory
echo "$LICENSE_CERT" > /tmp/nginx_ingress_license_client.cert
echo "$LICENSE_KEY" > /tmp/nginx_ingress_license_client.key

sudo mv /tmp/nginx_ingress_license_client.cert /etc/docker/certs.d/private-registry.nginx.com/client.cert
sudo mv /tmp/nginx_ingress_license_client.key /etc/docker/certs.d/private-registry.nginx.com/client.key

# Pull all of the available image tags and then normalize the output so that it's only "regular images"  IE. remove the alpine, ot, ubi, etc. images
image_tags=`curl https://private-registry.nginx.com/v2/nginx-ic/nginx-plus-ingress/tags/list --cert /etc/docker/certs.d/private-registry.nginx.com/client.cert --key /etc/docker/certs.d/private-registry.nginx.com/client.key --insecure`

if [[ "$image_tags" == *"error"* ]]; then
	>&2 echo "There was an error pulling the image tags: $image_tags"
	exit 1
fi

image_tags=`echo $image_tags | jq '.tags[]' | sed 's/\"//g' | sed 's/-.*//g' | uniq`

# Verify the ACR exists and then get the tags for the nginx plus ingress images
/usr/bin/az acr show --name $ACR_NAME --subscription $ACR_SUB_NAME > /dev/null

if [ "$?" != "0" ]; then
	>&2 echo "The $ARC_NAME container registry does not exist in the $ACR_SUB_NAME subscription"
	exit 1
fi

/usr/bin/az acr login --name $ACR_NAME --subscription $ACR_SUB_NAME > /dev/null

# If a regular login fails, attempt to use --expose-token
if [ "$?" != "0" ]; then
	/usr/bin/az acr login --name $ACR_NAME --subscription $ACR_SUB_NAME --expose-token > /dev/null
	
	# If this also fails, then fail the whole script
	if [ "$?" != "0" ]; then
		>&2 "Unable to login to container registry"
		exit 1
	fi
fi

acr_tags=`/usr/bin/az acr repository show-tags --name $ACR_NAME --subscription $ACR_SUB_NAME --repository nginx-plus-ingress | jq .[]  | sed 's/\"//g'`

changes=""

# Iterate through each of the image tags on the Nginx repo and verify they are in ACR
for nginx_tag in $image_tags; do
	found=false
	
	for acr_tag in $acr_tags; do
		if [ "$nginx_tag" == "$acr_tag" ]; then
			found=true
			break
		fi
	done
	
	if [ $found == false ]; then
		if [ "$DRY_RUN" == "false" ]; then
			docker pull private-registry.nginx.com/nginx-ic/nginx-plus-ingress:$nginx_tag
			docker tag private-registry.nginx.com/nginx-ic/nginx-plus-ingress:$nginx_tag $ACR_FQDN/nginx-plus-ingress:$nginx_tag
			docker push $ACR_FQDN/nginx-plus-ingress:$nginx_tag
			
			if [ "$?" != "0" ]; then
				echo "Error syncing image tag $nginx_tag to ACR"
				exit 1
			fi
			
			echo "Image tag $nginx_tag successfully synced to ACR"
		else
			changes="${changes}Sync image tag $nginx_tag to ACR"$'\n'
		fi
	fi
done

if [ "$changes" == "" ]; then
	changes="No changes to perform"
else
	changes="Change trigger: `uuidgen`"$'\n\n'"$changes"
fi

if [ "$run_type" == "data" ]; then
	jq -n --arg changes "$changes" '{ "changes": $changes }'
fi
