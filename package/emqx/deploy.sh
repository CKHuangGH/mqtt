helm repo add influxdata https://helm.influxdata.com/
helm repo add jetstack https://charts.jetstack.io
helm repo add emqx https://repos.emqx.io/charts
helm repo update

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# Install and start cert-manager
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true

# Install the EMQX
helm install --version 5.8.7 emqx emqx/emqx --namespace emqx --create-namespace 

helm install --version 2.1.2 influxdb2 influxdata/influxdb2 --namespace influxdb --create-namespace --set persistence.enabled=true --set persistence.storageClass=local-path --set persistence.size=30Gi --set config.authEnabled=false

# ---- InfluxDB 設定 ----
NAMESPACE="influxdb"  # InfluxDB 的 namespace
ORG="influxdata"
BUCKET="default"
INFLUX_HOST="http://influxdb-influxdb2.${NAMESPACE}.svc.cluster.local:8086"


# ---- Helm 安裝 Prometheus Stack ----
helm install --version 75.9.0 prometheus-community/kube-prometheus-stack \
  --generate-name \
  --namespace monitoring \
  --create-namespace \
  --set grafana.enabled=false \
  --set alertmanager.enabled=false \
  --set prometheus.service.type=NodePort \
  --set prometheus.prometheusSpec.scrapeInterval="5s" \
  --set prometheus.prometheusSpec.enableAdminAPI=true \
  --set prometheus.prometheusSpec.resources.requests.cpu="1000m" \
  --set prometheus.prometheusSpec.resources.requests.memory="1024Mi" \
  --set prometheus.prometheusSpec.remoteWrite[0].url="${INFLUX_HOST}/api/v2/write?org=${ORG}&bucket=${BUCKET}&precision=s" \
  --set prometheus.prometheusSpec.retention="5m" \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage="1Gi"
