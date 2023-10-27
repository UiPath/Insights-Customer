#!/bin/bash

echo ""
echo "Running log collection script"

# Define the container name and the user and the line break
container_name="looker-container"
user_home="${HOME}" # replace "username" with the actual username
line_break="----"

# Check if dzdo is available, if not use sudo
if command -v dzdo &> /dev/null
then
    sudo_cmd="dzdo"
else
    sudo_cmd="sudo"
fi
echo -e "\tsudo set to ${sudo_cmd}"

# Define the target directory and create it if doesn't exist
target_folder="lookerlogs"
target_directory="${user_home}/${target_folder}"
mkdir -p "${target_directory}"
echo -e "\tCreated target directory ${target_directory}"

# Go to the user's home directory 
cd "${user_home}"
echo -e "\tSwiched to working directory to ${user_home}"

# Define an array with the paths of the files to copy
files_to_copy=("/app/nginx/nginx_stderr.log" "/app/nginx/nginx_stdout.log" "/app/workdir/webapp_stderr.log" "/app/workdir/webapp_stdout.log" "/app/workdir/lookerinitout" "/app/workdir/lookeriniterr" "/app/workdir/lookerout" "/app/workdir/lookererr")

echo -e ""
echo -e "\t$line_break Copying log files $line_break"


# Loop through the array and copy each file
for file in "${files_to_copy[@]}"; do
    echo -e "\tCopying file: $file"
    $sudo_cmd docker cp "${container_name}:${file}" "${target_directory}"
done

# Get date specific files in .deploy directory
insights_deploy_dir=$($sudo_cmd docker inspect looker-container | jq -r '.[0].HostConfig.Binds' | grep 'deploy' | awk -F':/app/.deploy:Z' '{print $1}' | awk -F'"' '{print $2}')

echo -e "\tCopying files installer-certificate*, init_status and looker-init* from ${insights_deploy_dir}"
$sudo_cmd cp ${insights_deploy_dir}/install-certificate* "${target_directory}"
$sudo_cmd cp ${insights_deploy_dir}/looker-init* "${target_directory}"
$sudo_cmd cp ${insights_deploy_dir}/init_status* "${target_directory}"
echo -e ""
echo -e "\t$line_break Generating looker/docker/system info $line_break"

echo -e "\tiptables config: $sudo_cmd iptables -L"
$sudo_cmd iptables -L > "${target_directory}"/iptables.config

echo -e "\tfirewalld daemon status: $sudo_cmd systemctl status firewalld"
$sudo_cmd systemctl status firewalld > "${target_directory}"/firewalld.status

echo -e "\tfirewalld config: $sudo_cmd firewall-cmd --list-all-zones"
$sudo_cmd firewall-cmd --list-all-zones> "${target_directory}"/firewalld.zones

echo -e "\tDocker daemon logs: $sudo_cmd journalctl --no-pager -u docker"
$sudo_cmd journalctl --no-pager -u docker > "${target_directory}"/docker.service.logs

echo -e "\tDocker daemon status: $sudo_cmd systemctl status docker"
$sudo_cmd systemctl status docker > "${target_directory}"/docker.service.status

echo -e "\tDocker daemon config: $sudo_cmd systemctl cat docker"
$sudo_cmd systemctl cat docker > "${target_directory}"/docker.service.config

echo -e "\tDocker inspect: $sudo_cmd docker inspect looker-container"
$sudo_cmd docker inspect looker-container > "${target_directory}"/looker-container.inspect

echo -e "\tDocker status: $sudo_cmd docker info"
$sudo_cmd docker info > "${target_directory}"/docker.info

echo -e "\tLooker-container status: $sudo_cmd docker ps -a"
$sudo_cmd docker ps -a > "${target_directory}"/looker-container.status

echo -e "\tIP Forward status: sudo_cmd cat /proc/sys/net/ipv4/ip_forward"
$sudo_cmd cat /proc/sys/net/ipv4/ip_forward > "${target_directory}"/ip_forward.status

echo -e "\tLooker services status: $sudo_cmd docker exec looker-container supervisorctl status all"
$sudo_cmd docker exec looker-container supervisorctl status all > "${target_directory}"/supervisorctl.status


# Generate zip files
echo -e ""
echo -e "\t$line_break Generating zip file $line_break"
echo -e "\tGenerating zip file lookerlogs.zip at ${user_home}/lookerlogs.zip"
if $($sudo_cmd zip -r lookerlogs.zip "${target_folder}" 1>/dev/null); then
    echo -e "\tZip operation successful. Deleting the '${target_directory}' directory..."
    $sudo_cmd rm -rf ${target_directory}
else
    echo "-e \tZip operation failed. '${target_directory}' directory was not deleted."
    echo -e "Clean up logs with the command: sudo rm -r ${target_directory}"
fi

host_ip=$(hostname -i)
echo -e ""
echo -e "Use the following command on windows to transfer the file: \n\tscp $USER@${host_ip}:${user_home}/lookerlogs.zip <preferred directory>"
echo -e "Where preferred directory is the target directory on the windows machine. i.e:\n\tscp $USER@${host_ip}:${user_home}/lookerlogs.zip C:\Temp\lookerlogs.zip"
echo -e ""