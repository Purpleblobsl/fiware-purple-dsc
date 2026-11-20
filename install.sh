#!/bin/sh
set -eu

#* helpers
die() { printf "\e[1;31merror\e[0m: ${*:-???}\n" >&2; exit 1; }
HELM() {
    printf "\e[1;92mhelm --kubeconfig \"%s\" %s\e[0m\n" "$KUBECONFIG" "$*"
    helm --kubeconfig "$KUBECONFIG" "$@"
}
need_arg() { [ ! "$#" -lt 2 ] || die "missing value for $1"; }

#* env
# defaults
[ -f ./.env ] || die "'./.env' file not found"
. ./.env

# get CMD
case "${1:-}" in
    i|install|      \
    d|delete|       \
    u|upgrade|      \
    ud|upgradebug|  \
    id|debug|       \
    r|render|       \
    h|help) CMD="$1"; shift || true ;;
    *)      CMD="install" ;;
esac

# options
while [ $# -gt 0 ]; do
    case "$1" in
        -N|--name)        need_arg "$@"; NAME="$2"; shift 2 ;;
        -n|--namespace)   need_arg "$@"; NAMESPACE="$2"; shift 2 ;;
        -f|--values)      need_arg "$@"; VALUES="$2"; shift 2 ;;
        -b|--base-values) need_arg "$@"; VALUES_BASE="$2"; shift 2 ;;
        -c|--chart)       need_arg "$@"; CHART="$2"; shift 2 ;;
        -o|--output)      need_arg "$@"; OUTPUT="$2"; shift 2 ;;
        *) die "invalid option '$1'\nTry './install.sh help' for more info" ;;
    esac
done

#* sanity checks
[ -f "$VALUES" ] \
    || die "'$VALUES' not found (\$VALUES)"
[ -f "$VALUES_BASE" ] \
    || die "'$VALUES_BASE' not found (\$VALUES_BASE)"
[ -f "$KUBECONFIG" ] \
    || die "KUBECONFIG must be set to a valid kubeconfig file"
command -v helm >/dev/null \
    || die "'helm' needs to be installed"
[ "$OUTPUT" = "-" ] && OUTPUT="/dev/null"

#* run
case "$CMD" in
    i|install)
        HELM install "$NAME" --create-namespace --namespace "$NAMESPACE" \
            -f "$VALUES_BASE" -f "$VALUES" "$CHART"
    ;; d|delete)
        HELM del -n "$NAMESPACE" "$NAME"
    ;; u|upgrade)
        HELM upgrade --install "$NAME" "$CHART" \
            --create-namespace --namespace "$NAMESPACE" \
            -f "$VALUES_BASE" -f "$VALUES"
    ;; ud|upgradebug)
        HELM upgrade --debug --dry-run --install "$NAME" "$CHART" \
            --create-namespace --namespace "$NAMESPACE" \
            -f "$VALUES_BASE" -f "$VALUES" | tee "$OUTPUT"
    ;; id|debug)
        HELM install --debug --dry-run "$NAME" "$CHART" \
            --create-namespace --namespace "$NAMESPACE" \
            -f "$VALUES_BASE" -f "$VALUES" | tee "$OUTPUT"
    ;; r|render)
        HELM template "$NAME" "$CHART" \
            --namespace "$NAMESPACE" \
            -f "$VALUES_BASE" -f "$VALUES" | tee "$OUTPUT"
    ;; h|help)
        . ./.env # Note: reset defaults
        cat <<EOF 1>&2
Usage: ./install.sh [COMMAND] [OPTIONS...]
COMMANDS:
    i,  install         : install Helm release
    u,  upgrade         : upgrade or install release
    d,  delete          : delete Helm release
    r,  render          : get the rendered YAML
    id, debug           : dry-run Helm install with debug output
    ud, upgradebug      : dry-run Helm upgrade with debug output
    h,  help            : print this message

OPTIONS:
    -N, --name          : chart deploy name (def: $NAME)
    -n, --namespace     : chart deploy namespace (def: $NAMESPACE)
    -f, --values        : target values (def: $VALUES)
    -b, --base-values   : base values (def: $VALUES_BASE)
    -c, --chart         : chart path (def: $CHART)
    -o, --output        : debug output path, use '-' to disable (def: $OUTPUT)

EXAMPLES:
    # render template using 'values.test.yaml', and only output to 'stdout'
    ./install.sh render -f values.test.yaml -o -

    # upgrade "my-chart" deployment using 'values.prod.yaml'
    ./install.sh upgrade -f values.prod.yaml -N my-chart

NOTES:
    - If no command is provided, "install" is used
    - Options must go after the command.
EOF
        exit 1
    ;; *) die "invalid command '$CMD'\nTry './install.sh help' for more info" ;;
esac

