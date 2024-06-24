# Example ci/cd demo

# Hypothesis
we assume dockerhub image [`duluku/flask-hello-world`](https://hub.docker.com/repository/docker/duluku/flask-hello-world/general) as our ml docker images, and tag with `dev`, `staging`, `prod`. 

Related to the github repository [`nimohunter/flask-helloworld`](https://github.com/nimohunter/flask_helloworld) with `release/dev`, `release/staging`, `release/prod` branches.

# Typical Develop Procudure 

1. developer write the code in iteration branch, for example : `dev/iteration-Jun`
2. `dev/iteration-Jun` branch merge into `release/dev` and invoke CI/CD pipeline.
3. CI: build the docker image, use `release/dev` branch to generate docker image tag `dev`.
4. CD: deploy the docker image use helm chart to kubernetes. (different Kubernetes or different namespace in same Kubernetes)
5. check the result and modify the code and continue the develop loop step 1 to step 5.
6. if everything all right, then merge `release/dev` to `release/staging`, invoke the staging CI/CD. provide the service to inner use to integrated test. 
7. if everything all right, then merge `release/staging` to `release/prod`, invoke the prod CI/CD.
8. finally merge `release/prod` into `main`


# heml chart 
Here is use helm chart to control the whole ml project to depoly in kubernetes.

you can see we have three env:

* `values-dev.yaml` for Development
* `values-staging.yaml` for Staging
* `values-prod.yaml` for Production

# CI/CD
we can see the ci in .github/workflows/docker-build-push.yaml in  [`nimohunter/flask-helloworld`](https://github.com/nimohunter/flask_helloworld),which can help me to build image and upload to dockerhub if anthing change in these branches: release/dev,release/staging,release/prod.

and other is cd in .github/workflows/deploy-k8s.yml, help us to deploy. in this case, i just deploy in different namespace.

# Seperate depoly location (Isolation)

we may deploy the different env in different kubernetes, seperate the data and traffic.

but it's cost a lot, so sometimes we use namespace to seperate, deply the application into these namespaces using Helm and specifying the namespace during the deployment.

Create all the namespace in the minikube
```bash
minikube start

kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace prod
```

deploy :

```bash
helm install ml-api . -f values-dev.yaml --namespace dev

helm install ml-api . -f values-staging.yaml --namespace staging

helm install ml-api . -f values-prod.yaml --namespace prod
```

run the test, and we can see the success, and the dev pod return the dev info "Hello, World From Dev Env" 
```bash
helm test ml-api --namespace dev
helm test ml-api --namespace staging
# we don't think we need test in prod environment.
# helm test ml-api --namespace prod

# check the log
kubectl logs -n dev -l "job-name=ml-api-test-response"
```

or we can use proxy to check the flask response, see the different response:

```bash 
kubectl proxy

curl http://localhost:8001/api/v1/namespaces/dev/services/ml-api-helm-flask-helloworld:5000/proxy/
Hello, World From Dev Env%  
curl http://localhost:8001/api/v1/namespaces/staging/services/ml-api-helm-flask-helloworld:5000/proxy/
Hello, World From Staging Env%                                                 
curl http://localhost:8001/api/v1/namespaces/prod/services/ml-api-helm-flask-helloworld:5000/proxy/
Hello, World From Prod Env%    

```

## Healthy detect And auto scaling (availability)
Autoscaling allows the application to handle changes in load by automatically adjusting the number of running instances.Which can reduces costs and maintains application performance. 

Health checks (liveness and readiness probes) ensure that the application is running smoothly and can serve traffic. Liveness probes keep the application running by restarting containers that fail, and readiness probes determine when a container is ready to start accepting traffic.

`values-prod.yaml` enable the function.

