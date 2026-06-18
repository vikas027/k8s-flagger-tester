# Usage

## FluxCD HelmRelease

Override the image in your Flagger load-tester HelmRelease values:

```yaml
image:
  repository: vikas027/k8s-flagger-tester
  tag: latest
```

## Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flagger-loadtester
  namespace: test
spec:
  selector:
    matchLabels:
      app: loadtester
  template:
    metadata:
      labels:
        app: loadtester
    spec:
      containers:
        - name: loadtester
          image: vikas027/k8s-flagger-tester:latest
          ports:
            - containerPort: 8080
```

## Example Flagger Canary

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: my-app
  namespace: default
spec:
  analysis:
    webhooks:
      - name: acceptance-test
        type: pre-rollout
        url: http://flagger-loadtester.test/
        timeout: 30s
        metadata:
          type: bash
          cmd: "hurl --test /tests/acceptance.hurl"
      - name: load-test
        url: http://flagger-loadtester.test/
        timeout: 5s
        metadata:
          type: bash
          cmd: "k6 run /tests/load.js"
```

## Pulling from Docker Hub

=== "Latest"
    ```bash
    docker pull vikas027/k8s-flagger-tester:latest
    ```

=== "Pinned version"
    ```bash
    docker pull vikas027/k8s-flagger-tester:0.1.0
    ```
