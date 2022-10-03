## Terraform Equinix Environment

This Terraform script uses the module found [here][module].

### Usage

Ensure you have access to both an Equinix and Tailscale account.

Copy the example vars file:

```bash
cp terraform.tfvars-example.json terraform.tfvars.json
```

_`terraform.tfvars.json` will be ignored in git_

Edit the values.

Then initialise and apply the plan:

```bash
terraform init
terraform apply
```

Don't forget to `terraform destroy` when you are done.

[module]: https://registry.terraform.io/modules/weaveworks-liquidmetal/liquidmetal/equinix/latest
[tailscale]: https://tailscale.com/
