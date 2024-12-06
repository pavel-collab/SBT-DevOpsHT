Это задание аналогично заданию 2 из 3 лабораторной работы. Только здесь мы будем деплоить приложение с использованием k8s.

```
docker build -t my-flask-app .

kubectl apply -f flask-deployment.yaml
kubectl apply -f flask-service.yaml

kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
kubectl apply -f postgres-pvc.yaml
```

```
minikube tunnel
```

```
minikube service flask-app-service
```