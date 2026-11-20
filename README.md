# Purple DSC Helm

Helm chart to ease the deployment of a **Fiware DSC**.

## Project

```
purple-dsc/
|-- templates/                      # templates to patch/extend functionality
|   |-- did-helper/                 # custom `did-helper` on the house
|   |-- managedMongo/               # mongo patch
|   |-- managedPostgres/            # postgres patch
|   |-- cm-patch/                   # "replace" for contract-management
|   |-- job-generator/              # custom Job generator
|   |-- _helpers.tpl
|   '-- NOTES.txt
|-- values/
|   |-- .env.template               # template .env
|   '-- values.template.yaml        # template values to render from
|-- Chart.yaml
|-- README.md                       # this file
|-- install.sh                      # install helper script
|-- render.sh                       # render values helper script
'-- values.yaml                     # base values
```

> **Note**:
> For detailed info about the helm and its quirks read the
> [./values.yaml](/values.yaml)

## Install

### Cluster setup:

You may need to install the
[mongodb community-operator](https://github.com/mongodb/helm-charts/tree/main/charts/community-operator#installing-community-operator)
beforehand if it is not already available in your cluster.

```bash
# add repo
helm repo add mongodb https://mongodb.github.io/helm-charts

# install
helm install community-operator mongodb/community-operator \
  --set operator.watchNamespace='*'
```

**Note**:
You may need to install the
[postgres operator](https://github.com/zalando/postgres-operator/blob/master/docs/quickstart.md#helm-chart)
beforehand if it is not already available in your cluster.

```bash
# add repo
helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator

# install
helm install postgres-operator postgres-operator-charts/postgres-operator
```

### Setup

#### Atutomated Setup

Run the helper `./render.sh` to automagically generate some values.

```bash
./render.sh \
    -n "<provider-name>" \
    -c "<country>" \
    -s "<state>" \
    -l "<locality>" \
    -o "<organization>" \
    -e "<email>" \
    -d "<data-space-host>"
```

> **Note**: Run `./render.sh --help` to see all available options and commands.

> **Note**:
> It will generate two files `./values/.env.x` and `./values/values.x.yaml`.

Now just setup the environment:

```bash
ln -fs ./values/.env.x ./.env
```

##### Example

```bash
./render.sh \
    -n "evil-corp" \
    -c "ES" \
    -s "Bizkaia" \
    -l "Bilbao" \
    -o "Evil Corp." \
    -e "evil@corp.com" \
    -d "evil-corp.com"
```

The output should look something like this:

```
Successfully generated provider values files:
  - './values/values.evil-corp.yaml'
  - './values/.env.evil-corp'

Keycloak user will be created with the following credentials:
  Username: evil 
  Password: KQnHPV97yfCpNszH

You can now install/upgrade the chart with the following command:

helm upgrade -n evil-corp p-evil-corp ./ \
    --create-namespace --install \
    -f ./values.yaml -f ./values/values.evil-corp.yaml

or 

ln -fs "./values/.env.evil-corp" ./.env
./install.sh upgrade
```

> **Note**:
> You can setup some envs for the render script:
>
> | env                               | default                                |
> |:---------------------------------:|:--------------------------------------:|
> | `CLUSTER_ISSUER`                  | `"letsencrypt-haproxy"`                |
> | `INGRESS_CLASS`                   | `"haproxy"`                            |
> | `REALM`                           | `"test-realm"`                         |
> | `STORAGE_CLASS`                   | `""`                                   |
> | `TRUSTED_ANCHOR_HOSTNAME`         | `"trust.example.com"`                  |

#### Manual Setup

1. Configure your environment by setting variables in `.env`

```bash
cp .env.example .env.prod
ln -sf .env.prod .env
```

> **Note**: Soft links are used to allow switching contexts more easily.

> **Note**: Follow the naming pattern `.env.*`.

2. Create a new values file based on the default `values.yaml`. For example:

```bash
cp values.yaml values.prod.yaml
```

> **Note**: Follow the naming pattern `values.*.yaml`.

3. Edit your `values.*.yaml` file to customize the deployment.

### Install

Use the helper script to install the Helm chart:

```bash
./install.sh
```

> **Note**: Run `./install.sh help` to see all available options and commands.

> **Note**: Remember where `.env` is pointing

## Links

**Fiware**:

- Components:
  - [trusted-issuers-list](https://github.com/FIWARE/trusted-issuers-list)

- Helms:
  - [DSC](https://github.com/FIWARE/data-space-connector)
  - [decentralized-iam](https://github.com/FIWARE/decentralized-iam)
  - [vc-authentication](https://github.com/FIWARE/vc-authentication)
  - [odrl-authorization](https://github.com/FIWARE/odrl-authorization)
  - [Main helm repo](https://github.com/FIWARE/helm-charts/tree/main)

- Configuration examples:
  - [Provider](https://github.com/FIWARE/data-space-connector/blob/main/k3s/provider.yaml)
  - [Consumer](https://github.com/FIWARE/data-space-connector/blob/main/k3s/consumer.yaml)

- [Release notes](https://github.com/FIWARE/data-space-connector/tree/main/doc/release-notes)

**Misc**:

- [Helm hooks](https://helm.sh/docs/topics/charts_hooks/)

