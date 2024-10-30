# POC: Declarative management of 'Kafka Topologies' using Crossplane

Like [Kafkakewl](https://github.com/MarshallWace/kafkakewl/tree/legacy-main), but using [Crossplane](https://github.com/crossplane/crossplane) and its Kafka provider to **declaratively administer and maintain** Kafka 'topologies' using Kubernetes CRDs. Does not implement any of the imperative actions supported by Kafkakewl (e.g. recreations of topics), and does not implement in-cluster RBAC (since this would be managed in Git/k8s) or metrics (since this is a minimal POC). Coverage of complicated parts of ACL functionalities (see functions defined [here](https://github.com/MarshallWace/kafkakewl/blob/legacy-main/kewl-kafkacluster-processor/src/main/scala/com/mwam/kafkakewl/processor/kafkacluster/deployment/KafkaClusterItems.scala)) is missing.

## Further work to make this operational

- Implementation of additional ACL patterns, like:
  - Developer access of predefined level (`full/readonly`) applied to an array of developer users
  - ACL pattern requirements for common tools: Kafka streams, Confluent Replicator
  - ACL patterns for cross-namespace/cross-manifest access and how this is managed
- Testing setup: Likely a combination of bash scripts, using `crossplane` CLI to render manifests which can then be validated with `yq`.
- Fix ACLs not getting their state set to 'ready', despite being synced to Kafka
- Explore how to improve the experience of working on this, perhaps (a) split composition into multiple manifests; (b) define the Go template in a separate file as Crossplane should support this for sure; (c) explore other 'nicer' templating functions/libraries available for Crossplane

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
# your cluster must be able to resolve/reach the brokers.
# update the IP/port below for your setup. Add auth arguments as per the Kafka provider docs if relevant.
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

# get topologies - at this point, if all is synced/ready, go check Kafka that topics are there. To troubleshoot, view k8s events.
kubectl get topologies --all-namespaces

# cleanup - delete the Topology and its topics. Go check Kafka afterwards to check topics were deleted.
kubectl delete -f ./topology.yaml

# cleanup - delete test cluster
k3d cluster delete test
```

