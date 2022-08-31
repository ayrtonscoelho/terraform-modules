# Testes de default workloads

---

### ArgoCD

1. Acessar o console do Secrets Manager e buscar pelo segredo com o seguinte padrão para localizar a senha do usuário **admin**.

```
 <CLUSTER_NAME>-secret-argocd-admin
```

2. Realizar um **Port Foward** do *service* **argocd-server** e efetuar o login como **admin**.

3. Realizar o **refresh** de todas as aplicações.


### Kong Ingress Controller

1. Acessar o console de Load Balancers, procurar por um ALB recente do tipo **classic**.

2. Validar se em **Instâncias > Status** está como **InService**.

3. Criar apontamento DNS na Cloudflare para o Load Balancer.



### External Secrets

1. Criar **ClusterSecretStore**

```
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  annotations:
  name: aws-cluster-secret-store
spec:
  controller: ''
  provider:
    aws:
      auth: {}
      region: <AWS_REGION>
      service: SecretsManager
  refreshInterval: 0
```


2. Criar **ExternalSecret**

```
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  annotations:
  name: <SECRET_NAME>
  namespace: <CONSUMER_NAMESPACE>
spec:
  dataFrom:
    - extract:
        conversionStrategy: Default
        decodingStrategy: None
        key: <AWS_SECRET_MANAGER_NAME>
  refreshInterval: 30s
  secretStoreRef:
    kind: ClusterSecretStore
    name: aws-cluster-secret-store
  target:
    creationPolicy: Owner
    deletionPolicy: Retain
    name: <SECRET_NAME>
```


3. Criar **Deployment** 

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: nginx
  annotations:
    reloader.stakater.com/auto: "true"
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        envFrom:
          - secretRef:
              name: <SECRET_NAME>
        ports:
        - containerPort: 80
```


### Reloader (Secrets)

Validar que o **Deployment** possui a **annotation** a seguir:

```
reloader.stakater.com/auto: "true"
```


### EBS CSI Driver

1. Criar **PersistentVolumeClaim (PVC)**

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <PVC_NAME>
  namespace: <CONSUMER_NAMESPACE>
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: <PVC_SIZE>Gi
```


2. Atachar **PVC** em algum **Pod**

```
apiVersion: v1
kind: Pod
metadata:
  name: <POD_NAME>
  namespace: <CONSUMER_NAMESPACE>
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: persistent-storage
      mountPath: <MOUNT_PATH>
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: <PVC_NAME>
```

3. Acessar shell do pod e criar algum arquivo no path montado e depois apagar o pod e criar de novo. Após isso acessar o shell novamente e validar se o arquivo criado ainda persiste.



### External DNS

Blocked (To Do)



### Grafana Ingress

1. Alterar o **values.yaml** do kube-prometheus-stack
```
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: kong
      konghq.com/https-redirect-status-code: '302'
      konghq.com/protocols: https
      konghq.com/strip-path: 'true'
    labels: {}
    path: /
    pathType: Prefix

    hosts:
      - grafana-sre-test.owill.com.br
    https: true
    extraPaths: []
    backend:
      service:
        name: kube-prometheus-stack-grafana
        port:
          name: http
    tls: []
```


### Calico addon (Network Policy)

Seguir passo a passo do teste realizado neste documento oficial da AWS.

```
https://docs.aws.amazon.com/pt_br/eks/latest/userguide/calico.html
  ```


### New Relic K8s Agent

Ace#ssar o New Relic e validar se o cluster está adicionado e recebendo métricas.

```
https://onenr.io/0bRmDrZGrwy
```


### Aplicação teste paulao-api-test


Aplicar o manifesto abaixo para subir a API utilizando os seguintes workloads defaults:

- External Secret

- Reloader

- KEDA

- NewRelic


```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: paulao-api-test
  namespace: argocd
spec:
  destination:
    namespace: paulao-api-test
    server: https://kubernetes.default.svc
  #Bloco para o Argo ignorar o aumento de replicas baseado em HPA.
  ignoreDifferences:
    - group: apps
      jsonPointers:
        - /spec/replicas
      kind: Deployment
      name: paulao-api-test
      namespace: paulao-api-test
  project: foundation-sre
  source:
    path: paulao-api-test
    repoURL: https://github.com/ayrtonscoelho/terraform-modules.git
    targetRevision: argo_test
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    retry:
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 3m0s
      limit: 5
    syncOptions:
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
  ```


### Karpenter (Node Autoscaling)

O Karpenter e seus manifestos são instalados via ArgoCD, então após subir o cluster só será necessário executar os testes.

Documentação completa -> https://karpenter.sh

1- Certificar-se que as **Subnets** e **Security Groups** associados ao cluster possuem as seguintes **Tags** associadas: 

```
karpenter.sh/discovery/cluster: ${CLUSTER_NAME}
```

2- Aplicar o manifesto para criar um deployment de teste.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      terminationGracePeriodSeconds: 0
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
          resources:
            requests:
              cpu: 1
  ```

3- Executar o comando para aumentar a quantidade de replicas do deployment criado e forçar scaling de **nodes**.

```
kubectl scale deployment inflate --replicas 15
  ```

4- Executar o comando para visualizar os logs do Karpenter e validar o funcionamento.

```
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter -c controller
  ```

5- Verificar se os **nodes** subiram e se os **pods do deployment** também.