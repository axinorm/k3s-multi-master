# k3s-multi-master

Set the base of the infrastructure to work with k3s multi master

## Requirements

* bash v4+
* Docker v19.03.2+
* aws cli v1.16.169+, with an aws access configurer
* A ssh key created for the project

## Deployment

### Setup base

For Ansible deployments, you have to rename all.template.yml to all.yml and add your own values

Create and launch the workstation (docker container)
```
./workstation/launch.sh
```

Go into workdir
```
cd workdir/
```

Deploy the layers
```
./infra-builder-terraform.sh --account <account_name> [--plan]

# or you can select a particular layer
./infra-builder-terraform.sh --account <account_name> --category <category_name> --layer <layer_name> [--plan]
```

Generate inventory
```
./infra-make-inventory.sh
```
Provision the infrastructure
```
./infra-provisioning-base.sh
```