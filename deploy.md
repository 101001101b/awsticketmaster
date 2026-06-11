# Deploy Guide — AWSTicket (AWS Academy Learner Lab)

## 1. Prerrequisitos

| Herramienta | Version | Como verificar |
|---|---|---|
| AWS CLI | >= 2.x | `aws --version` |
| Terraform | >= 1.5 | `terraform --version` |
| Docker | >= 24.0 | `docker --version` |
| Python | >= 3.11 | `python --version` |

**Credenciales del Learner Lab:**
1. Inicia tu Learner Lab desde AWS Academy
2. Copia Access Key, Secret Key y Session Token de "AWS Details"
3. Edita `infra/terraform.tfvars` y pega las credenciales

---

## 2. Configurar variables

Edita `infra/terraform.tfvars`:

```hcl
aws_access_key_id     = "<ACCESS_KEY>"
aws_secret_access_key = "<SECRET_KEY>"
aws_session_token     = "<SESSION_TOKEN>"

ami_id = "<AMI_ID>"

rabbitmq_user     = "admin"
rabbitmq_password = "tu-password-seguro"

postgres_password = "otra-password-segura"


## 3. Desplegar infraestructura

```powershell
cd infra

terraform init

terraform plan

terraform apply -auto-approve
```

**Duracion:** 8-12 minutos.

**Outputs:**
```
rabbitmq_private_ip  = 10.0.1.10
postgres_private_ip  = 10.0.1.20
ecr_repository_url   = <account>.dkr.ecr.eu-west-1.amazonaws.com/awsticket/worker
s3_bucket_id         = awsticket-results-<account>
ecs_cluster_name     = awsticket-cluster
ecs_service_name     = awsticket-worker-svc
```

---

## 4. Build & Push imagen worker a ECR

```powershell
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin <ECR_URL>

cd worker
docker build -t awsticket/worker .
docker tag awsticket/worker:latest <ECR_URL>/awsticket/worker:latest
docker push <ECR_URL>/awsticket/worker:latest

aws ecs update-service --cluster awsticket-cluster --service awsticket-worker-svc --force-new-deployment
```

---

## 5. Verificar servicios

### RabbitMQ

```powershell
aws ssm start-session --target <rabbitmq-instance-id>

sudo systemctl status rabbitmq-server
sudo rabbitmqctl list_queues

curl -u admin:<password> http://localhost:15672/api/queues
```

### PostgreSQL

```powershell
aws ssm start-session --target <postgres-instance-id>

sudo -u postgres psql -d ticketdb -c "SELECT COUNT(*) FROM seats;"

sudo -u postgres psql -d ticketdb -c "SELECT * FROM events;"
```

---

## 6. Experimentos

```powershell
cd experiments

python run_experiment.py --type calibration --rates 10,50,100 `
    --pg-host <postgres-ip> --pg-password <password>

python run_experiment.py --type speedup --workers 1,2,4,8 --rate 300 `
    --pg-host <postgres-ip> --pg-password <password>

python run_experiment.py --type elasticity `
    --pg-host <postgres-ip> --pg-password <password>

python run_experiment.py --type contention --hotspot-pct 5 --hotspot-traffic 80 `
    --pg-host <postgres-ip> --pg-password <password>
```

---

## 7. Autoscaling (automatico con EventBridge)

El Lambda se ejecuta cada 60s automaticamente. Verificar en CloudWatch Logs:

```powershell
aws logs tail /aws/lambda/awsticket-scaling-controller --follow
```

---

## 8. Resultados y plots

```powershell
cd analysis

$env:POSTGRES_HOST = "<postgres-ip>"
$env:POSTGRES_PASS = "<password>"
python export_results.py --s3-bucket awsticket-results-<account>

python plot_results.py --input-dir ./exports --output-dir ./plots
```

---

## 9. Dashboard CloudWatch

```
https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=awsticket-dashboard
```

---

## 10. Limpieza

```powershell
cd infra
terraform destroy
```

---

## Checklist

```
[ ] 1. terraform.tfvars con credenciales y AMI
[ ] 2. terraform init + apply
[ ] 3. docker build + push a ECR
[ ] 4. force-new-deployment ECS
[ ] 5. Verificar RabbitMQ + PostgreSQL
[ ] 6. Lanzar experimentos
[ ] 7. Exportar resultados a S3 + plots
[ ] 8. Dashboard CloudWatch
[ ] 9. terraform destroy
```
