# k3s-multi-master

Set the infrastructure for deploy K3S multi-master

## Requirements

* Docker
* A ssh key created for the project

## Deployment

### Setup

For Terraform deployments, you have to copy ``mygroup`` folder in ``configs`` and rename it with your groupe name, same with ``env`` folder with the name of your environment (for exemple ``dev``)

For Ansible deployments, you have to rename ``all.template.yml`` to ``all.yml`` and add your own values

Create and launch the workstation (docker container)
```
./workstation/launch.sh
```

Go into workdir
```
cd workdir/
```

Init project
```
./infra-bootstrap.sh --provider aws --account <group>-<env>
```

Deploy the layers
```
./infra-builder-terraform.sh --account <group>-<env> --layer <layer_name> [--plan]
```

Generate inventory
```
./infra-make-inventory.sh
```

Provision the infrastructure
```
./infra-provisioning.sh
```