#!/bin/sh


##                        ##
# !! WARNING - Untested !! #
##                        ##


#==================================
# Build Container Images in hcloud
#==================================
set -e

# Check whether container-registry credentials have been provided.
if [ -z $DD_DOCKERIO_USER ] ; then
	echo 'Error: $DD_DOCKERIO_USER is not set.'
	exit 1
fi
if [ -z $DD_DOCKERIO_PASSWORD ] ; then
	echo 'Error: $DD_DOCKERIO_PASSWORD is not set.'
	exit 1
fi
if [ -z $DD_GHCRIO_USER ] ; then
	echo 'Error: $DD_GHCRIO_USER is not set.'
	exit 1
fi
if [ -z $DD_GHCRIO_PASSWORD ] ; then
	echo 'Error: $DD_GHCRIO_PASSWORD is not set.'
	exit 1
fi

# Check whether a name for the SSH key of the administrator has been provided.
if [ -z $DD_SSH_ADMIN_KEY_NAME ] ; then
	echo 'Error: $DD_SSH_ADMIN_KEY_NAME is not set.'
	exit 1
fi
sshAdminKeyName="${DD_SSH_ADMIN_KEY_NAME}"

# Check whether an API token has been provided.
if [ -z $DD_HCLOUD_TOKEN ] ; then
	echo 'Error: $DD_HCLOUD_TOKEN is not set.'
	exit 1
fi

# Override any previously active hcloud API token.
export HCLOUD_TOKEN="${DD_HCLOUD_TOKEN}"

# Determine `server-type` to use.
if [ -z $DD_HCLOUD_SERVER_TYPE ] ; then
	echo 'Error: $DD_HCLOUD_SERVER_TYPE is not set.'
	table=$(hcloud server-type list)
	echo 'See the following table for available options:'
	echo "${table}"
	exit 1
fi
serverType="${DD_HCLOUD_SERVER_TYPE}"

# Check whether a location for the cloud-server has been provided.
if [ -z $DD_HCLOUD_SERVER_LOCATION ] ; then
	echo 'Error: $DD_HCLOUD_SERVER_LOCATION is not set.'
	table=$(hcloud location list)
	echo 'See the following table for available options:'
	echo "${table}"
	exit 1
fi
serverLocation="${DD_HCLOUD_SERVER_LOCATION}"

# Check whether an OS image name has been provided.
if [ -z $DD_HCLOUD_SERVER_IMAGE ] ; then
	echo 'Error: $DD_HCLOUD_SERVER_IMAGE is not set.'
	table=$(hcloud image list)
	echo 'See the following table for available options:'
	echo "${table}"
	exit 1
fi
serverImage="${DD_HCLOUD_SERVER_IMAGE}"

# Generate servername.
serverName=$(date --utc +%Y%m%d-%H%M%S-%N)

# Generate a new SSH key.
sshKeyFile="./ssh-${serverName}_ed25519"
ssh-keygen -q \
	-t ed25519 \
	-f "${sshKeyFile}" \
	-P ''

# Read SSH public-key
sshPublicKey=$(
	ssh-keygen -y -q \
		-f "${sshKeyFile}"
)
echo "Public Key: ${sshPublicKey}"

# Upload SSH public-key to cloud.
sshKeyName="${serverName}_ssh"
hcloud ssh-key create \
	--name="${sshKeyName}" \
	--public-key="${sshPublicKey}" \
	--label 'generator=dlang-dockerized__tools__hcloud-build-images.sh'

# Create a new cloud-server.
hcloud server create \
	--name="${serverName}" \
	--type="${serverType}" \
	--location="${serverLocation}" \
	--image="${serverImage}" \
	--ssh-key="${sshKeyName}" \
	--ssh-key="${sshAdminKeyName}" \
	--primary-ipv6 \
	--primary-ipv4

# Delete SSH public-key from cloud.
hcloud ssh-key delete "${sshKeyName}"

# Setup the created cloud-server.
hcloud server ssh "${serverName}" -i "${sshKeyFile}" \
	sh -ec '
		apt-get update
		apt-get -y dist-upgrade
		apt-get -y install \
			containerd \
			docker.io \
			git \
			hcloud-cli \
			php-cli \
			screen
	'

# SSH: Upload build-script.
echo "#!/bin/sh
	sh -exc \"
		git clone 'https://github.com/dlang-dockerized/packaging' dlang-dockerized
		cd dlang-dockerized
		./ddct generate-all
		./ddct build-selection
		./ddct namespace-copy 'dlangdockerized' #docker.io (no prefix)
		./ddct namespace-copy 'ghcr.io/dlang-dockerized/images'

		docker login docker.io -u '${DD_DOCKERIO_USER}' -p '${DD_DOCKERIO_PASSWORD}'
		docker login ghcr.io '${DD_GHCRIO_USER}' -p '${DD_GHCRIO_PASSWORD}'

		CONTAINER_NAMESPACE='ghcr.io/dlang-dockerized/images' ./ddct namespace-publish
		CONTAINER_NAMESPACE='dlangdockerized' ./ddct namespace-publish

		export HCLOUD_TOKEN='${HCLOUD_TOKEN}'
		hcloud delete '${serverName}'
\"" | \
	hcloud server ssh "${serverName}" -i "${sshKeyFile}" \
		-T 'cat > ~/build-dlang-dockerized-images.sh'

hcloud server ssh "${serverName}" -i "${sshKeyFile}" \
	'screen -d -m bash --init-file "~/batch-dlang-dockerized.sh"'

exit 0
