
# Blue-Green Deployment on AKS

## Step 1: Build and Push Docker Images

```bash
docker build -t <acr>/blue-green-app:blue -f Dockerfile .
docker build -t <acr>/blue-green-app:green -f Dockerfile . --build-arg START_FILE=server-green.js
docker push <acr>/blue-green-app:blue
docker push <acr>/blue-green-app:green
```

## Step 2: Deploy to AKS

```bash
kubectl create ns bluegreen-demo
kubectl apply -n bluegreen-demo -f k8s/blue-deployment.yaml
kubectl apply -n bluegreen-demo -f k8s/service.yaml
```

## Step 3: Switch to Green

```bash
kubectl apply -n bluegreen-demo -f k8s/green-deployment.yaml
kubectl patch svc myapp-service -n bluegreen-demo -p '{"spec": {"selector": {"app": "myapp", "version": "green"}}}'
```

## Step 4: Cleanup

```bash
kubectl delete ns bluegreen-demo
```
