# Deploy to AWS EC2 with Terraform

## Start Terraform CLI
```
sudo docker run \
 -e AWS_ACCESS_KEY_ID='xxx' \
 -e AWS_SECRET_ACCESS_KEY='xxx' \
 -e TF_VAR_interactsh_access_token='xxx'\
 -e TF_VAR_domain='xxx.bar'\
 -e TF_VAR_godaddy_access_token='xxx' \
 -e TF_VAR_godaddy_ns1='xxx.bar/records/A/ns1xxx' \
 -e TF_VAR_godaddy_ns2='xxx.bar/records/A/ns2xxx' \
 -it --rm -w /app \
 -v $(pwd)/terraform:/app \
 --entrypoint /bin/sh \
 hashicorp/terraform:latest
```

## Terraform commands
Exectue deployment
```
terraform apply
```

Other useful Terraform commands
```
terraform init
terraform fmt
terraform validate
terraform plan
terraform show
terraform output
terraform destroy
```

# Starting the Client
## CLI
https://github.com/projectdiscovery/interactsh#interactsh-cli-client
```
sudo docker run projectdiscovery/interactsh-client -server https://coredefender.club -token 'gtB78X4y9EwcF4SuYgSe2lCl8Sf2LDbwNAitksl' -persist  -n 10 -v
```

## WebClient
https://github.com/projectdiscovery/interactsh-web