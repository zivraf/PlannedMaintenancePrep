#!/bin/bash

# This script creates resources for planned maintenance validation.
subId='c42e6286-971c-46ff-9ec6-6f24fc4e0e1a'

rgName='zivrRG'
regionName='centraluseuap'
userName='zivruser'
prefix='zivtst'

#ARM VMs
azure config mode arm

#select a subscription
az account set -s $subId

#delete a myResourceGroup
az group delete --name $rgName --yes --no-wait

# Create a resource group.
az group create --name $rgName --location $regionName

# Create a new virtual machine with generated SSH Keys.
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "create VM srvSI0 in order to generate SSH keys"
    az vm create --resource-group $rgName --name $prefix'srvSI0' --image UbuntuLTS  --size Standard_DS1 --admin-username $userName --generate-ssh-keys
    exit 0
fi


vnetName=$rgName'vnet'
#create vnNet
az network vnet create --resource-group $rgName --location $regionName --name $vnetName --address-prefix 192.168.0.0/16 --subnet-name $vnetName'1' --subnet-prefix 192.168.1.0/24

# create additional 5 VMs with the same ssh key
for i in `seq 1 3`; do
  az vm create --resource-group $rgName --name $prefix'srvSI'$i --image UbuntuLTS  --vnet-name $vnetName --subnet  $vnetName'1' --size Standard_DS1 --admin-username $userName --ssh-key-value ~/.ssh/id_rsa.pub  --no-wait
done

# Create the first availability set to be used for maintenance redeploy
availSetName=$prefix'availset1'
az vm availability-set create --resource-group $rgName --name $availSetName --platform-fault-domain-count 1 --platform-update-domain-count 2

# create VMs 11-13 in an availability set
for i in `seq 1 3`; do
  az vm create --resource-group $rgName --name $prefix'srvMI1'$i --availability-set $availSetName  --vnet-name $vnetName --subnet  $vnetName'1' --image UbuntuLTS --size Standard_DS1 --admin-username $userName --ssh-key-value ~/.ssh/id_rsa.pub  --no-wait
done

# Create the second availability set to be used for FDHE
availSetName=$prefix'availset2'
az vm availability-set create --resource-group $rgName --name $availSetName --platform-fault-domain-count 1 --platform-update-domain-count 2

# create VMs 11-13 in an availability set
for i in `seq 1 3`; do
  az vm create --resource-group $rgName --name $prefix'srvMI2'$i --availability-set $availSetName   --vnet-name $vnetName --subnet  $vnetName'1'  --image UbuntuLTS --size Standard_DS1 --admin-username $userName --ssh-key-value ~/.ssh/id_rsa.pub  --no-wait
done


# Create the third availability set to be used for DEMOs
availSetName=$prefix'availset3'
az vm availability-set create --resource-group $rgName --name $availSetName --platform-fault-domain-count 1 --platform-update-domain-count 2

# create VMs 31-33 in an availability set
for i in `seq 1 3`; do
  az vm create --resource-group $rgName --name $prefix'srvMI3'$i --availability-set $availSetName --image UbuntuLTS --size Standard_DS1 --admin-username $userName --ssh-key-value ~/.ssh/id_rsa.pub  --no-wait
done

azure config mode asm

azure vm create $prefix'ClassicsrvVM' b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-16_04-LTS-amd64-server-20170610-en-us-30GB g $userName -p $userName'1234P!' -z "Small" -e -l "Central US EUAP"
