# Example ci/cd demo

# Hypothesis
Assume the ml-application project is github repository [`nimohunter/flask-helloworld`](https://github.com/nimohunter/flask_helloworld) with `release/dev`, `release/staging`, `release/prod` branches.

It's just a simple Flask API Server to pretend to be a ml-api project.

# CI/CD Summary
The ml engineer just care about the ml related code in application project. the github workflows `ci.yml` will help the user, if `release/dev`, `release/staging`, `release/prod` branches is change, and it will build the docker and push to docerhub automaticlly.

After the CI workflows finished, then the `cd.yml` start (Use Workflow Dependencies), deploy the image to k8s. 
We can store the helm repo in same place with application repo, but i like to store separately, everyone just need to care about their own work, so i store helm chart code repo in [generic-ml-deploy-helm](https://github.com/nimohunter/generic-ml-deploy-helm) and i wish to upload helm package to other platform,like ChartMuseum,Harbor, but in this time, i just store in my local machine.

# Ml application Develop Procudure

1. developer write the code in iteration branch, for example : `dev/iteration-Jun`
2. `dev/iteration-Jun` branch merge into `release/dev` and invoke CI/CD pipeline.
3. CI: build the docker image, use `release/dev` branch to generate docker image tag `dev`.
4. CD: deploy the docker image use helm chart to kubernetes. (different Kubernetes or different namespace in same Kubernetes)
5. check the result and modify the code and continue the develop loop step 1 to step 5.
6. if everything all right, then merge `release/dev` to `release/staging`, invoke the staging CI/CD. provide the service to inner use to integrated test. 
7. if everything all right, then merge `release/staging` to `release/prod`, invoke the prod CI/CD.
8. finally merge `release/prod` into `main`


# Helm chart explian(generic)
Here is use helm chart to control the whole ml project to depoly in kubernetes. here is helm chart code repo: [generic-ml-deploy-helm](https://github.com/nimohunter/generic-ml-deploy-helm)
you can see we have three env:

* `values-dev.yaml` for Development
* `values-staging.yaml` for Staging
* `values-prod.yaml` for Production

```bash
# local usage Deploy using a specific Docker image with namespace in staging
helm install my-ml-release ./ -f values-dev.yaml  --namespace dev  --set image.repository=duluku/flask-hello-world
```

### Seperate depoly location (Isolation)

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
 helm install my-ml-release ./ -f values-dev.yaml  --namespace dev  --set image.repository=duluku/flask-hello-world
 helm install my-ml-release ./ -f values-staging.yaml  --namespace staging  --set image.repository=duluku/flask-hello-world
 helm install my-ml-release ./ -f values-prod.yaml  --namespace prod  --set image.repository=duluku/flask-hello-world
```


### Case Test 
run the test, and we can see the success, and the dev pod return the dev info "Hello, World From Dev Env" 
```bash
helm test my-ml-release --namespace dev
helm test my-ml-release --namespace staging
# we don't think we need test in prod environment.
# helm test my-ml-release --namespace prod

# check the log
kubectl logs -n dev -l "job-name=my-ml-release-test-connection"
```

or we can use proxy to check the flask response, see the different response:

```bash 
kubectl proxy

curl http://localhost:8001/api/v1/namespaces/dev/services/my-ml-release-generic-ml-deploy-helm:5000/proxy/
Hello, World From Dev Env%  
curl http://localhost:8001/api/v1/namespaces/staging/services/my-ml-release-generic-ml-deploy-helm:5000/proxy/
Hello, World From Staging Env%                                                 
curl http://localhost:8001/api/v1/namespaces/prod/services/my-ml-release-generic-ml-deploy-helm:5000/proxy/
Hello, World From Prod Env%    

```

### Healthy detect And auto scaling (availability)
Autoscaling allows the application to handle changes in load by automatically adjusting the number of running instances.Which can reduces costs and maintains application performance. 

Health checks (liveness and readiness probes) ensure that the application is running smoothly and can serve traffic. Liveness probes keep the application running by restarting containers that fail, and readiness probes determine when a container is ready to start accepting traffic.

`values-prod.yaml` enable the function.

```yaml
enableAutoscaling: true
autoscaling:
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 50
```

# Terraform
Sometimes have to say, while CI/CD automates the software deployment lifecycle, Terraform automates and manages the infrastructure lifecycle. So i wish to use Terraform to provide the kubernetes cluster, load balance or other cloud service, so in this moment, i prefer use Terraform just to provide the EKS in AWS. 

1. Provision EKS Cluster: The `eks-cluster.tf` file sets up the EKS cluster along with the necessary IAM roles and policies.
2. Configure Access: The providers.tf file dynamically configures the Kubernetes and Helm providers using credentials obtained from the provisioned EKS cluster.
3. Ready for Deployment: With the cluster set up and providers configured, our CD pipeline can now use Helm to deploy applications to the Kubernetes cluster.

ps. sometimes we can use some Action in github market like [github-actions-deploy-eks-helm](https://github.com/bitovi/github-actions-deploy-eks-helm)

