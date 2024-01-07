gcp_region    = "us_central1"
gcp_project   = "terraform-on-gcp-403504"
zone_names    = ["us_central1", "us_east1"]
instname      = ["prod", "dev"]
subnet_region = ["us-east1", "us-east1"]
machine_type  = "e2-micro"
name_prefix   = "mig"
labels = {
  environment = "test"
}
mig_region = "us-east1"
mig_name   = "us-east1-mig"
metadata = {
  "startup-script" = "#! /bin/bash \nENV=$(curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/attributes/env)\nNAME=$(curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/name)\nZONE=$(curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/zone | sed 's@.*/@@')\nPROJECT=$(curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/project/project-id)\nsudo yum install -y httpd\nsudo systemctl start httpd\nsudo chmod 777 /var/www/html\nsudo cat <<EOF> /var/www/html/index.html\n<body style=\"font-family: sans-serif\">\n<html><body><h1>Aaaand.... Success!</h1>\n<p>My machine name is <span style=\"color: #3BA959\">$NAME</span> and I serve the <span style=\"color: #3BA959\">$ENV</span> environment.</p>\n<p>I live comfortably in the <span style=\"color: #5383EC\">$ZONE</span> datacenter and proudly serve Tony Bowtie on the <span style=\"color: #D85040\">$PROJECT</span> project.</p>\n<p><img src=\"https://storage.googleapis.com/tony-bowtie-pics/tony-bowtie.svg\" alt=\"Tony Bowtie\"></p>\n</body></html>\nEOF\nsudo systemctl restart httpd"
}

lb-name          = "mig-app-lb"
fb-service       = "mig-frontend-service"
backend-svc-name = "mig-backend-service"
bg-protocol      = "HTTP"