#!/bin/bash

NAMESPACE=$1
USER=$1

kubectl create ns $NAMESPACE
kubectl create sa $USER -n $NAMESPACE

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $USER-secret
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: $USER
type: kubernetes.io/service-account-token
EOF

cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: $NAMESPACE
  name: $USER
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
EOF

cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $USER
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: $USER
  apiGroup: ""
roleRef:
  kind: Role
  name: $USER 
  apiGroup: rbac.authorization.k8s.io
EOF

export SA_SECRET_TOKEN=$(kubectl -n $NAMESPACE get secret/$USER-secret -o=go-template='{{.data.token}}' | base64 --decode)

export CLUSTER_NAME=$(kubectl config current-context)

export CURRENT_CLUSTER=$(kubectl config view --raw -o=go-template='{{range .contexts}}{{if eq .name "'''${CLUSTER_NAME}'''"}}{{ index .context "cluster" }}{{end}}{{end}}')

export CLUSTER_CA_CERT=$(kubectl config view --raw -o=go-template='{{range .clusters}}{{if eq .name "'''${CURRENT_CLUSTER}'''"}}"{{with index .cluster "certificate-authority-data" }}{{.}}{{end}}"{{ end }}{{ end }}')

export CLUSTER_ENDPOINT=$(kubectl config view --raw -o=go-template='{{range .clusters}}{{if eq .name "'''${CURRENT_CLUSTER}'''"}}{{ .cluster.server }}{{end}}{{ end }}')

cat << EOF > $USER-config
apiVersion: v1
kind: Config
current-context: ${CLUSTER_NAME}
contexts:
- name: ${CLUSTER_NAME}
  context:
    namespace: $NAMESPACE
    cluster: ${CLUSTER_NAME}
    user: $USER
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    certificate-authority-data: ${CLUSTER_CA_CERT}
    server: ${CLUSTER_ENDPOINT}
users:
- name: $USER
  user:
    token: ${SA_SECRET_TOKEN}
EOF
