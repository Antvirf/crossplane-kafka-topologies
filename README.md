# Kafkakewl-like management of 'Kafka Topologies' using Crossplane

Like Kafkakewl, but using Crossplane and its Kafka provider to manage creation of Kafka 'topologies' using Kubernetes CRDs.


## To-do

- Review at all resources KafkaKewl creates, complete todo for resources to manage
  Topics
  ACLs
  ...users? groups? offsets?
- Add management of ACLs, as derived from applications and relationships


## Test setup

```bash
# create cluster with k3d
k3d cluster create test

# install crossplane with helm  https://docs.crossplane.io/latest/software/install/#install-crossplane
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane 

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
kubectl -n crossplane-system create secret generic kafka-creds --from-file=credentials=secret.json

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

