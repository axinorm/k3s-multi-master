#!/usr/bin/env bash
set -e

# default values :
help=false
action=apply
region=eu-west-1

while true; do
    case "$1" in
    --help)
        help=true
        shift ;;
    --provider)
        provider=$2
        shift 2 ;;
    --account)
        account=$2
        group=$(echo $2 | cut -d'-' -f1)
        env=$(echo $2 | cut -d'-' -f2-)
        shift 2 ;;
    --region)
        region=$2
        shift 2 ;;
    --plan)
        action=plan
        shift ;;
    --destroy)
        action=destroy
        shift ;;
    --layer)
        layer=$2
        shift 2 ;;
    '')
        break;;
    *)
        echo "Invalid argument $1";
        exit 1
  esac
done

if [ "$help" = true ] || [ -z "$account" ] || [ -z "$region" ] || [ -z "$action" ]; then
    echo "Usage:
    ./infra-bootstrap.sh \\
        --provider aws \\
        --account <group>-<env> \\
        [--region eu-west-1] \\
        [--plan] \\
        [--destroy]"
    exit 1
fi

config_dir="./../../../configs/${group}/${env}/terraform"
bootstrap_dir="./terraform/bootstrap/${provider}/"

options=""
if [ "$action" = "apply" ] || [ "$action" = "destroy" ]; then
    options="-auto-approve"
fi

cd $bootstrap_dir
terraform init
terraform ${action} ${options} -var=group=${group} -var=env=${env} -var=region=${region} -state=${config_dir}/bootstrap-${provider}-${region}.tfstate
