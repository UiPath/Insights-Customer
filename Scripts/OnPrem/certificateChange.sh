#!/bin/bash

usage() {
    echo "Script for updating the insights cert.pfx file"
    echo "Usage: $0 -c <path_to_pfx> -s <FQDN>"
    echo "  -c    Specify the PFX file."
    echo "  -s    Specify the server name of the linux server"
    echo ""
    echo "NOTE: The certificate should contain a SAN attribue for the linux server name."
    echo "      Additionally it should be a FQDN name"
    exit 1
}

# check that valid arguments are given.
function check_args() {
    if [[ -z "$PFX_FILE" || -z "$FQDN" ]]; then
    echo "FATAL: Both PFX_FILE (-c) and server name (-s) must be provided."
    usage
    fi
}

# Check if a valid pfx file is given as input
function check_pfx_exists() {

    echo "Checking that the PFX file exists at: $PFX_FILE"
    if [[ ! -e "$PFX_FILE" ]]; then
        echo "FATAL: The provided PFX file: $PFX_FILE does not exist."
        exit 1
    fi
    echo "  PFX file exists"
    echo ""

}

# Get the password for the PFX
function get_pfx_password() {

    echo "Checking for PFX password"
    echo "  Executing: openssl pkcs12 -info -in "$PFX_FILE" -noout -passin pass: &>/dev/null"
    # Try to read PFX info without a password
    openssl pkcs12 -info -in "$PFX_FILE" -noout -passin pass:"" &>/dev/null

    # Get the password and then verify the password
    if [ $? -ne 0 ]; then
        echo "Please enter the password for the PFX file:"
        read -s PFX_PASSWORD

        echo ""
        echo "  Checking PFX password: openssl pkcs12 -info -in "$PFX_FILE" -noout -passin pass: **** 1>/dev/null"
        openssl pkcs12 -info -in "$PFX_FILE" -noout -passin pass:$PFX_PASSWORD &>/dev/null
        if [ $? -ne 0 ]; then
            echo "FATAL: Failed to access PFX with given password"
            echo "FATAL: Check password or try running above command manually"
            exit 1
        fi
    else 
        echo "  No password needed"
    fi
    
    echo ""
}

# Check that the pfx has a valid san attribue
check_san_from_pfx() {

    echo "Checking the SAN attribue"
    echo "  Executing: openssl pkcs12 -in "$PFX_FILE" -passin pass:**** -nokeys -clcerts -out tmp.pem"
    # Extract the certificate from the PFX file
    openssl pkcs12 -in "$PFX_FILE" -passin pass:$PFX_PASSWORD -nokeys -clcerts -out /tmp/tmp.pem

    if [ $? -ne 0 ]; then
        echo "FATAL: Failed to create pem formated file"
        exit 1
    fi

    # Extract the SAN information
    echo "  Extracting the SAN attribue: openssl x509 -in /tmp/tmp.pem -noout -text | grep -A 1 "Subject Alternative Name:" | tail -n1"
    local san=$(openssl x509 -in /tmp/tmp.pem -noout -text | grep -A 1 "Subject Alternative Name:" | tail -n1)

    if [ $? -ne 0 ]; then
        echo "FATAL: Failed to read SAN info"
        echo "Cleaning up /tmp/tmp.pem"
        rm /tmp/tmp.pem
        exit 1
    fi

    # Clean up the temporary certificate
    echo "  Removing temp cert: /tmp/tmp.pem"
    rm -f /tmp/tmp.pem

    
    # Print the SAN (or you can process it further if needed)
    if [[ $san =~ $FQDN ]]; then
        echo "  The certificate has a valid san attribute for $FQDN"
    else
        # replace everything up to the first period with a wildcard
        FQDN2=$(echo $FQDN |  sed 's/[^.]*/\\\*/')
        if [[ $san =~ $FQDN2 ]]; then
            echo "  The certificate has a valid san attribute for $FQDN"
        else
            echo "FATAL: The certificate does not have a valid san attribute for: $FQDN"
            echo "FATAL: The san attributes are: $san"
            exit 1
        fi
    fi

    echo ""
 
}


# Convert the PFX to a PFX with no password
function convert_pfx() {
    
    echo "Converting the PFX for installation"

    # Run this inside the container so we do not have FIPS issues
    echo "  Extracting cert in pem format."
    echo "  Executing: openssl pkcs12 -in $PFX_FILE -out $INSIGHTS_DIR/tmp.pem -nodes -passin pass:***"
    openssl pkcs12 -in $PFX_FILE -out $INSIGHTS_DIR/tmp.pem -nodes -passin pass:$PFX_PASSWORD

    if [ $? -ne 0 ]; then
        echo "FATAL: Extration command failed!"
        echo "FATAL: Checking permissons on $PWD"
        exit 1
    fi

    echo "  Executing:  chmod 744 $INSIGHTS_DIR/tmp.pem"
        if [ $? -ne 0 ]; then
        echo "FATAL: Failed to set perms on $INSIGHTS_DIR/tmp.pem"
        echo "FATAL: Checking permissons on $PWD"
        exit 1
    fi

    echo "  Creating new cert.pfx at $INSIGHTS_DIR/cert.pfx"
    echo "    Checking if $INSIGHTS_DIR/cert.pfx exists"
    if [[ -e "$INSIGHTS_DIR/cert.pfx" ]]; then
        randomN=$RANDOM
        echo "    The file $INSIGHTS_DIR/cert.pfx exists moving to $INSIGHTS_DIR/cert.pfx_$randomN"
        echo "    Executing:  mv $INSIGHTS_DIR/cert.pfx $INSIGHTS_DIR/cert.pfx_$randomN"
         mv $INSIGHTS_DIR/cert.pfx $INSIGHTS_DIR/cert.pfx_$randomN
        if [ $? -ne 0 ]; then
            echo "FATAL: Could not move file"
            echo "Cleaning up /tmp/tmp.pem"
            rm "/tmp/tmp.pem"
            exit 1
        fi
    fi

    echo "  Creating new cert.pfx"
    echo "    Executing:  docker exec -it looker-container openssl pkcs12 -export -in /app/.deploy/tmp.pem -out /app/.deploy/cert.pfx -passout pass:"
     docker exec -it looker-container openssl pkcs12 -export -in /app/.deploy/tmp.pem -out /app/.deploy/cert.pfx -passout pass:

    if [[ $? -ne 0 ]]; then
        echo "Fatal: Failed to create $INSIGHTS_DIR/cert.pfx"
        echo "Cleaning up $INSIGHTS_DIR/tmp.pem"
        rm "$INSIGHTS_DIR/tmp.pem"
        exit 1
    fi 
    
    echo "    Executing:  chmod 744 $INSIGHTS_DIR/cert.pfx"
     chmod 744 $INSIGHTS_DIR/cert.pfx
    
    if [[ $? -ne 0 ]]; then 
       echo "Fatal: Failed to set perms on $INSIGHTS_DIR/cert.pfx" 
       exit 1
    fi
    
    
    echo "  Successfully created $INSIGHTS_DIR/cert.pfx"
    echo ""


}


# Check if a specific docker container is running
function check_docker_container() {

    echo "Checking that the docker container is running:   docker ps -q -f name=looker-container"
    if [[ -z $( docker ps -q -f name=looker-container) ]]; then
        echo "FATAL: Docker container $CONTAINER_NAME is not running."
        echo "FATAL: Try:  systemctl restart docker"
        exit 1
    fi

    echo "  Docker container is running"
    echo ""
}

# Fine the location of insights
function set_insights_dir() {
    echo "Setting insights working directory"
    echo "  Executing:  docker inspect looker-container | jq -r '.[0].HostConfig.Binds' | grep 'deploy' | awk -F':/app/.deploy' '{print $1}' | awk -F'\"' '{print $2}'"
    INSIGHTS_DIR=$(docker inspect looker-container | jq -r '.[0].HostConfig.Binds' | grep 'deploy' | awk -F':/app/.deploy' '{print $1}' | awk -F'"' '{print $2}')
    
    if [ $? -ne 0 ]; then
        echo "FATAL: Could not set the insights working directory"
        echo "FATAL: Try running command manually to see the error"
        exit 1
    fi

    echo "  Verifying that $INSIGHTS_DIR exists"
    if [[ ! -e $INSIGHTS_DIR ]]; then
        echo "FATAL: Insights directory is missing!"
        echo "FATAL: Open a ticket with UiPath to repair this"
        exit 1
    fi 

    echo ""
}

# Run the certificate update
function run_certificate_update() {
    echo "Running certificate update"
    echo "  Executing: docker exec -it looker-container su looker -m -c '</app/looker-init-job/install-certificate.sh bash'"

    docker exec -it looker-container su looker -m -c '</app/looker-init-job/install-certificate.sh bash'

    if [ $? -ne 0 ]; then
        echo "FATAL: Certificate update failed"
        echo "FATAL: Check the log at" $(ls -rt $INSIGHTS_DIR | grep install-certificate | tail -n 1)
        exit 1
    fi

    echo "  Certificate update command executed successfully"
    echo ""
}

function remove_cert() {
     # Check the response
    echo "Removing $INSIGHTS_DIR/cert.pfx? (Its not password protected)"
    read -p "Do you want to proceed? [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echo "Cleaning up $INSIGHTS_DIR/cert.pfx"
            sudo rm -f $INSIGHTS_DIR/cert.pfx
            ;;
        *)
            echo "Removal aborted."
            ;;
    esac
}

# Check for command flags
while getopts ":c:s:h" opt; do
    case $opt in
        c)
            PFX_FILE="$OPTARG"
            ;;
        s)
            FQDN="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done


# Main execution
check_args

# Check if the user is sudo or root
if [[ $EUID -ne 0 ]]; then
    echo "FATAL: This script must be run as root or with sudo"
    exit 1
fi
echo "Starting Certificate Rotation Process"
echo ""
check_pfx_exists
get_pfx_password
check_san_from_pfx
check_docker_container
set_insights_dir
convert_pfx
run_certificate_update
echo "Complated Certificate Rotation Process, certificate should be updated"
