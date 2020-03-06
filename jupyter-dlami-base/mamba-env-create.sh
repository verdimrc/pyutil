#!/bin/bash

env=$1
specdir=$2

declare env=ds
declare specdir=specdir
declare -a pkgs=()

parse_args() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -h|--help)
            echo "Usage: ${BASH_SOURCE[0]} [-n|--environment ENV_NAME] [-d|--spec-dir SPEC_DIR]"
            echo "ENV_NAME: defaults to ds"
            echo "SPEC_DIR: defaults to specdir"
            exit 0
            ;;
        -n|--environmentu)
            env=$2
            shift 2
            ;;
        -d|--spec-dir)
            specdir=$2
            shift 2
            ;;
        *)
            shift
            ;;
        esac
    done

}

# Parse CLI arguments
parse_args "$@"
echo env=$env
echo specdir=$specdir
echo


##############################################################################
# Boostrap environment
##############################################################################
py=$(cat << EOF
import yaml
import sys
pkgs = [pkg for pkg in yaml.safe_load(open('$specdir/env.yml'))['dependencies'] if isinstance(pkg, str) and pkg.startswith("python")]
for pkg in pkgs:
    if pkg.startswith("python=") or pkg.startswith("python>") or pkg.startswith("python<"):
        print(pkg)
        sys.exit(0)
EOF
)
echo mamba create -y -n $env $(python -c "$py") pip
mamba create -y -n $env $(python -c "$py") pip
echo


##############################################################################
# Conda packages
##############################################################################
py=$(cat << EOF
import yaml
pkgs = [pkg for pkg in yaml.safe_load(open('$specdir/env.yml'))['dependencies'] if isinstance(pkg, str)]
print('\n'.join(pkgs))
EOF
)

# Install conda packages
while read -r line; do
  pkgs+=("$line")
done < <(python -c "$py")
echo mamba install -n $env "${pkgs[@]}"
mamba install -y -n $env "${pkgs[@]}"
echo

# Python script to get pip packages specified in environment file
py=$(cat << EOF
import yaml
pkgs = [pkg for pkg in yaml.safe_load(open('$specdir/env.yml'))['dependencies'] if not isinstance(pkg, str)]
for pkg in pkgs:
    print('\n'.join(pkg['pip']))
EOF
)


##############################################################################
# Install pip packages
##############################################################################
pip_bin=$(conda env list | grep "^$env " | awk '//{print $2}')/bin/pip

# pip packages specified in environment file
declare -a pkgs=()
while read -r line; do
  pkgs+=("$line")
done < <(python -c "$py")

echo $pip_bin install "${pkgs[@]}"
$pip_bin install "${pkgs[@]}"

# pip packages in requirements.txt
if [[ -f $specdir/requirements.txt ]]; then
    echo $pip_bin install $specdir/requirements.txt
    $pip_bin install $specdir/requirements.txt
    echo
fi

# pip packages to be installed with --no-deps
if [[ -f $specdir/requirements-nodeps.txt ]]; then
    echo $pip_bin install --no-deps -r $specdir/requirements-nodeps.txt
    $pip_bin install --no-deps -r $specdir/requirements-nodeps.txt
fi
