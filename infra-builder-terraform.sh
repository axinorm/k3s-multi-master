#!/usr/bin/env bash
set -e

help=false
action=apply
region=eu-west-1

while true; do
    case "$1" in
    --help)
        help=true
        shift ;;
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
    --category)
        inputCategory=$2
        shift 2 ;;
    --layer)
        inputLayer=$2
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
    ./infra-builder-terraform.sh \\
        --account <group>-<env> \\
        [--category 001-main-aws] \\
        [--layer 001-vpc] \\
        [--region eu-west-1] \\
        [--plan] \\
        [--destroy]"
    exit 1
fi


baseDir=$(pwd)
layers_dir="${baseDir}/terraform/layers"

relative_config_dir="./../../../../configs/${group}/${env}/terraform"

options=""
if [ "$action" = "apply" ] || [ "$action" = "destroy" ]; then
    options="-auto-approve"
fi

optionsLs=""
if [ "$action" = "destroy" ]; then
    optionsLs="-r"
fi

function terraform_init() {
    category="$1"
    layer="$2"

    echo "### Initialize Layer : $category/$layer"
    echo "##################################################################################"

    terraform init \
        -backend-config "region=${region}" \
        -backend-config "dynamodb_table=${account}-${region}-tfstate-lock" \
        -backend-config "bucket=${account}-${region}-tfstate" \
        -backend-config "key=${layer}.tfstate" \
        -force-copy
}

function execLayer {
    category="$1"
    layer="$2"

    echo "### Execute Layer : $category/$layer"
    echo "##################################################################################"

    cd "${layers_dir}/001-main-aws/${layer}"
    terraform_init "$category" "$layer"
    terraform ${action} ${options} \
        -var-file ${relative_config_dir}/commons.tfvars \
        -var-file ${relative_config_dir}/layer-${layer}.tfvars
}

layerFound=false
for category in $(ls $optionsLs "${layers_dir}"); do
    if [ "$category" == "$inputCategory" ] || [ -z "$inputCategory" ]; then
        for layer in $(ls $optionsLs "${layers_dir}/${category}"); do
            if [ "$layer" == "$inputLayer" ] || [ -z "$inputLayer" ]; then
                layerFound=true
                execLayer "$category" "$layer"
            fi
        done
    fi
done

if [ "$layerFound" != "true" ]; then
    echo "Error -- no layer found"
    exit 1
fi
