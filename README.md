# Declarative management of 'Kafka Topologies' using Crossplane

Like [Kafkakewl](https://github.com/MarshallWace/kafkakewl/tree/legacy-main), but using [Crossplane](https://github.com/crossplane/crossplane) and its Kafka provider to **declaratively administer and maintain** Kafka 'topologies' using Kubernetes CRDs. Does not implement any of the imperative actions supported by Kafkakewl (e.g. recreations of topics), and does not implement RBAC (since this would be managed in Git/k8s) or metrics (since this is a minimal POC).

## To-do

- Figure out proper principals and prefixes for relationships to see if it all works well
- Add test scripts to fetch ACLs and Topics to show functionality
- Fix ACLs not getting to 'ready' state, despite being synced


## Test setup

```bash
# create cluster with k3d
k3d cluster create test

# install crossplane with helm  https://docs.crossplane.io/latest/software/install/#install-crossplane
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane --namespace sys-crossplane --create-namespace crossplane-stable/crossplane --wait

# install Kafka provider and required functions
kubectl apply -f ./01-crossplane-providers-and-packages.yaml

# following Kafka provider setup, create a secret https://github.com/crossplane-contrib/provider-kafka
# update the IP/port below for your setup. Add auth arguments as per the docs if relevant.
cat <<EOF > secret.json
{
  "brokers": [
    "ip-of-your-kafka-bootstrap-brokers:port"
  ]
}
EOF

# create secret
kubectl -n sys-crossplane create secret generic kafka-creds --from-file=credentials=secret.json

# apply Kafka provider config
kubectl apply -f ./02-kafka-providerconfig.yaml

# apply xrd
kubectl apply -f ./03-compositeresourcedefinition.yaml

# apply composition
kubectl apply -f ./04-composition.yaml

# create sample topolgoy
kubectl apply -f ./topology.yaml

# get topologies - at this point, if all is synced/ready, go check Kafka that topics are there. To troubleshoot, view k8s events
kubectl get topologies --all-namespaces

# cleanup - delete the Topology and its topics. Go check Kafka afterwards to check topics were deleted.
kubectl delete -f ./topology.yaml

# cleanup - delete test cluster
k3d cluster delete test
```

