#!/bin/sh
set -eu

DIR="./values"
TEMPLATE_YAML="$DIR/values.template.yaml"
TEMPLATE_YAML="$DIR/values.template-central-marketplace.yaml"
TEMPLATE_ENV="$DIR/.env.template"

: "${CLUSTER_ISSUER="letsencrypt-haproxy"}"
: "${INGRESS_CLASS="haproxy"}"
: "${REALM="test-realm"}"
: "${STORAGE_CLASS=""}"
: "${TRUSTED_ANCHOR_HOSTNAME="trust.example.com"}"

## helpers ####################################################################

usage() {
    cat <<EOF
Usage: $0 [Flags...] [Options...]
Flags:
  -n <name>
        Name of the provider
  -c <country>
        Country (e.g., ES)
  -s <state>
        State (e.g., Bizkaia)
  -l <locality>
        Locality (e.g., Bilbao)
  -o <organization>
        Organization (e.g., My Company)
  -e <email>
        Email for the Keycloak user"
  -d <ds-host>
        Data-Space host name (e.g my-ds.com)
Options:
  -h    Print this message and exit
Notes:
    All flags are mandatory
EOF
    exit 0
}
die() { printf "%s\n" "$0:error: ${*:-???}" >&2; exit 1; }

## program ####################################################################

#* sanity checks

[ -f "$TEMPLATE_YAML" ] \
    || die "Template file not found at '$TEMPLATE_YAML'"
command -v openssl >/dev/null \
    || die "'openssl' is not installed"

#* get vars

# parse flags using getopts
while getopts "n:s:l:o:e:d:c:h" opt; do
  case "${opt}" in
    c) COUNTRY="${OPTARG}" ;;
    d) DS_HOST="${OPTARG}" ;;
    e) EMAIL="${OPTARG}" ;;
    l) LOCALITY="${OPTARG}" ;;
    n) DS_NAME="${OPTARG}" ;;
    o) ORGANIZATION="${OPTARG}" ;;
    s) STATE="${OPTARG}" ;;
    h) usage ;;
    \?) die "Invalid option: -${OPTARG}. See '$0 -h'" ;;
    :) die "Option -${OPTARG} requires an argument. See '$0 -h'" ;;
  esac
done

# helper to check if vars are set, export and generate "$VARS_TO_SUBST"
required_vars="
COUNTRY:${COUNTRY:-}
DS_HOST:${DS_HOST:-}
DS_NAME:${DS_NAME:-}
EMAIL:${EMAIL:-}
LOCALITY:${LOCALITY:-}
ORGANIZATION:${ORGANIZATION:-}
STATE:${STATE:-}

CLUSTER_ISSUER:${CLUSTER_ISSUER:-}
INGRESS_CLASS:${INGRESS_CLASS:-}
REALM:${REALM:-}
STORAGE_CLASS:${STORAGE_CLASS:-}
TRUSTED_ANCHOR_HOSTNAME:${TRUSTED_ANCHOR_HOSTNAME:-}
"

# generate a random PASSWORD (16 characters)
PASSWORD="$(openssl rand -base64 12 | tr -d '\n')"
export PASSWORD

DEVICE_PASSWORD="$(openssl rand -base64 12 | tr -d '\n')"
export DEVICE_PASSWORD
APISIX_PASSWORD="$(openssl rand -base64 12 | tr -d '\n')"
export APISIX_PASSWORD

# generate USERNAME from EMAIL (part before @)
USERNAME="${EMAIL%@*}"
export USERNAME

# check flags are provided, export variables and add them to VARS_TO_SUBST
VARS_TO_SUBST="\$USERNAME \$PASSWORD \$OUTPUT_YAML"
VARS_TO_SUBST="\$USERNAME \$PASSWORD \$OUTPUT_YAML \$APISIX_PASSWORD \$DEVICE_PASSWORD"
while IFS=: read -r name value; do
    [ -n "${name:-}" ]  || continue # skip empty lines
    [ -n "${value:-}" ] || die "All flags are mandatory. See '$0 -h'"
    export "${name?}"
    VARS_TO_SUBST="\$${name} ${VARS_TO_SUBST}"
done <<EOF # Hack: to not create a subshell
$required_vars
EOF

#* Gen

OUTPUT_YAML="$DIR/values.${DS_NAME}.yaml"
export OUTPUT_YAML
OUTPUT_ENV="$DIR/.env.${DS_NAME}"

# TODO: HERE FIX THIS
envsubst "$VARS_TO_SUBST" < "$TEMPLATE_YAML" > "$OUTPUT_YAML"
envsubst "$VARS_TO_SUBST" < "$TEMPLATE_ENV"  > "$OUTPUT_ENV"

# notes
cat <<EOF
Successfully generated provider values files:
  - '$OUTPUT_YAML'
  - '$OUTPUT_ENV'

Keycloak user will be created with the following credentials:
  Username: $USERNAME
  Password: $PASSWORD

You can now install/upgrade the chart with the following command:

helm upgrade -n $DS_NAME p-$DS_NAME ./ \\
    --create-namespace --install \\
    -f ./values.yaml -f $OUTPUT_YAML

or

ln -fs "$OUTPUT_ENV" ./.env
./install.sh upgrade
EOF

