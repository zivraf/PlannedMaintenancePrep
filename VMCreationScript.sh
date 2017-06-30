#!/bin/bash

# This script creates resources for planned maintenance validation.
subId='3fecd24e-94e2-43db-9991-898cfde35e7a'
rgName='zivrPlannedMaintValidationRG'
regionName='centraluseuap'
userName='zivruser'
prefix='zivr'


#select a subscription
az account set -s $subId

#delete a myResourceGroup
az group delete --name $rgName --yes --no-wait

# Create a resource group.
az group create --name $rgName --location $regionName

# Create a new virtual machine, this creates SSH keys.
az vm create --resource-group $rgName --name $prefix'srvSI0' --image UbuntuLTS  --size Standard_DS1 --admin-username $userName --generate-ssh-keys

# create additional 5 VMs with the same ssh key
for i in `seq 1 3`; do
  create --resource-group $rgName --name $prefix'srvS2'$i --image UbuntuLTS  --size Standard_DS1 --admin-username $userName --ssh-key-value ~/.ssh/id_rsa.pub  --no-wait
done


# Create the first availability set to be used for maintenance redeploy
availSetName = $prefix'availset1'
az vm availability-set create --resource-group $rgName --name $availSetName --platform-fault-domain-count 1 --platform-update-domain-count 2

# create VMs 11-13 in an availability set
for i in `seq 1 3`; do
  az vm create --resource-group $rgName --name $prefix'srvMI1'$i --availability-set $availSetName --image UbuntuLTS --size Standard_DS1 --admin-username $userName --ssh-key-value ~/.ssh/id_rsa.pub  --no-wait
done

# Create the second availability set to be used for FDHE
availSetName = $prefix'availset2'
az vm availability-set create --resource-group $rgName --name $availSetName --platform-fault-domain-count 1 --platform-update-domain-count 2

# create VMs 11-13 in an availability set
for i in `seq 1 3`; do
  az vm create --resource-group $rgName --name $prefix'srvMI2'$i --availability-set $availSetName --image UbuntuLTS --size Standard_DS1 --admin-username $userName --ssh-key-value ~/.ssh/id_rsa.pub  --no-wait
done


# Create the third availability set to be used for DEMOs
availSetName = $prefix'availset3'
az vm availability-set create --resource-group $rgName --name $availSetName --platform-fault-domain-count 1 --platform-update-domain-count 2

# create VMs 31-33 in an availability set
for i in `seq 1 3`; do
  az vm create --resource-group $rgName --name $prefix'srvMI3'$i --availability-set $availSetName --image UbuntuLTS --size Standard_DS1 --admin-username $userName --ssh-key-value ~/.ssh/id_rsa.pub  --no-wait
done
