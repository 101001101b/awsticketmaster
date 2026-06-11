project_name = "awsticket"
aws_region   = "us-east-1"

# ── Credenciales (Se pasan por variables de entorno, dejar vacío aquí) ──
aws_access_key_id     = ""
aws_secret_access_key = ""
aws_session_token     = ""

# ── AMI (buscar en EC2 > Launch Instance > Amazon Linux 2023) ───
ami_id = "ami-0152204c1a187337c"

# ── Credenciales servicios ───────────────────────────────────────
rabbitmq_user     = "admin"
rabbitmq_password = "CHANGEME_RABBIT_PASSWORD"

postgres_password = "CHANGEME_POSTGRES_PASSWORD"