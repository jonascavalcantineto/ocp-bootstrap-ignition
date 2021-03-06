#!/bin/bash

OCP_API="api api-int"
OCP_APPS='*.apps'
nodes="${OCP_API} ${OCP_APPS} ${MASTERS_DNS_NAMES} ${ETCD_DNS_NAMES} ${APP_NODES_DNS_NAMES} ${INFRA_NODES_DNS_NAMES}"

echo "Setting permission to $(whoami) user "
sudo chown $(whoami):$(whoami) ${OCP_USER_PATH} -R

ifFQDNisActive(){
  if [ ${CLUSTER_ID} == "" ]
  then
    fqdn="${node}.${BASE_DOMAIN} SRV"
  else
    fqdn="${node}.${CLUSTER_ID}.${BASE_DOMAIN}"
  fi

  ip=`dig ${fqdn} +short`
  
  [[ -z "$ip" ]] && echo "false" || echo "true"
}

list_cluster_nodes_names(){
  echo "------------------list_cluster_nodes_names-------------------------"
  for node in ${nodes}
  do
    if [ ${CLUSTER_ID} == "" ]
    then
      echo "$node.${BASE_DOMAIN}"
    else
      echo "$node.${CLUSTER_ID}.${BASE_DOMAIN}"
    fi
    
  done
  echo "------------------END Listing Cluster DNS Names---------------------"
}

checking_cluster_dns_nodes_names() {
  
  list_cluster_nodes_names

  echo "------------------checking_cluster_dns_nodes_names------------------------"
  for node in ${nodes}
  do
    fqdnActive=$(ifFQDNisActive)
    if [  "$fqdnActive" == "true" ]
    then
      echo "[DNS OK] - ${fqdn}"
      #echo "Setting Hostname to ${node}.${CLUSTER_ID}.${BASE_DOMAIN}"
      #hostnamectl set-hostname ${node}.${CLUSTER_ID}.${BASE_DOMAIN}
    else
      echo "----------------------------------------------------------------------------"
      echo "[DNS FAIL] -${fqdn}"
      echo "!!For proceed the installation you need to configure all DNS listed before!!"
      echo "----------------------------------------------------------------------------"
      exit 1
    fi  
  done
  echo "------------------END checking_cluster_dns_nodes_names---------------------"
}


setSSHKeyOnNodes(){
  echo "Enable SSH KEYS"
  ssh-keygen -t rsa -b 4096 -N '' -f ${OCP_USER_PATH}/.ssh/id_rsa
  chmod 700  ${OCP_USER_PATH}/.ssh
  chmod 600  ${OCP_USER_PATH}/.ssh/id_rsa
  chmod 644  ${OCP_USER_PATH}/.ssh/id_rsa.pub

  eval "$(ssh-agent -s)"
  ssh-add  ${OCP_USER_PATH}/.ssh/id_rsa
  /set-ssh-keys-nodes.sh
}

subscribeBastionOnOpenshift(){
  echo "Active Openshift rhel-7-server-ose-3.11-rpms Repositorie"
  sudo subscription-manager repos --enable=rhel-7-server-ose-3.11-rpms
  echo "Intalling openshift-ansible package"
  sudo yum install -y openshift-ansible
}

subscribeRegisterNodes(){
    ansible-playbook ${OCP_USER_PATH}/playbooks/0-subscribe-register-nodes.yaml
}

subscribePoolNodes(){
    ansible-playbook ${OCP_USER_PATH}/playbooks/1-subscribe-pool-nodes.yaml
}

disableAllRepositories(){
    ansible-playbook ${OCP_USER_PATH}/playbooks/2-disable-all-repositories.yaml
}

subscribeRepositoriesOnNodes(){
    ansible-playbook ${OCP_USER_PATH}/playbooks/3-subscribe-repositories-nodes.yaml
}

prepareNodes(){
    ansible-playbook ${OCP_USER_PATH}/playbooks/4-prepare-nodes.yaml
}

prepareDockerNodes(){
    ansible-playbook ${OCP_USER_PATH}/playbooks/5-prepare-docker-nodes.yaml
}

prepareDockerMasters(){
    ansible-playbook ${OCP_USER_PATH}/playbooks/5-prepare-docker-master.yaml
}

checking_cluster_dns_nodes_names

setSSHKeyOnNodes

#subscribeBastionOnOpenshift

subscribeRegisterNodes

subscribePoolNodes

disableAllRepositories

subscribeRepositoriesOnNodes

prepareNodes

prepareDockerNodes

prepareDockerMasters