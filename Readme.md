# DNS with GoDaddy
https://dcc.godaddy.com/manage/foo.bar/dns

Create following Records in Domain `foo.bar`:
* A Record: `ns1canary` pointing to public IP of interactsh server
* A Record: `ns2canary` pointing to public IP of interactsh server

* NS Record: `canary` pointing to FQDN `ns1canary.foo.bar`
* NS Record: `canary` pointing to FQDN `ns2canary.foo.bar`


# Deploy to AWS EC2 with Terraform

## Tag AWS KeyPair
Tag your KeyPair with key:`InteractSh` and an empty value

## Start Terraform CLI
```
sudo docker run \
 -e AWS_ACCESS_KEY_ID='xxx' \
 -e AWS_SECRET_ACCESS_KEY='xxx' \
 -e TF_VAR_interactsh_access_token='xxx'\
 -e TF_VAR_domain='canary.foo.bar'\
 -e TF_VAR_godaddy_access_token='xxx' \
 -e TF_VAR_godaddy_ns1='foo.bar/records/A/ns1canary.foo.bar' \
 -e TF_VAR_godaddy_ns2='foo.bar/records/A/ns2canary.foo.bar' \
 -e TF_VAR_interactsh_version='v0.0.7' \
 -it --rm -w /app \
 -v $(pwd)/terraform:/app \
 --entrypoint /bin/sh \
 hashicorp/terraform:latest
```

## Execute Deployment with Terraform command
Exectue deployment
```
terraform apply
```

## Other useful Terraform commands
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
sudo docker run projectdiscovery/interactsh-client -server 'https://canary.foo.bar' -token '<token>' -persist -n 10 -v
```

## WebClient
https://github.com/projectdiscovery/interactsh-web


* Execute: `git clone https://github.com/projectdiscovery/interactsh-web.git`
* Execute: `yarn start`
* Go to `http://localhost:3000/`
* Enter custom host (without schema): `canary.foo.bar` and enter token.
* Then reload page!!!