# Terraform Infrastructure for Global Launch Showcase

These Terraform files define and manage all the necessary AWS resources for the Global Launch Showcase project. Using this configuration, you can create, update, and destroy the entire cloud infrastructure with simple commands.

### Prerequisites

1. **Terraform CLI**: [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).

2. **AWS Account & CLI**: Configure your AWS credentials locally so Terraform can access your account. You can do this by installing the [AWS CLI](https://aws.amazon.com/cli/) and running ``aws configure``.

### How to Use 

1. **Navigate to the Terraform directory:**

    ```bash
    cd terraform
    ```

2. **Initialize Terraform**:
This downloads the necessary provider plugins.

    ```bash
    terraform init
    ```

3. **Review the plan**:
Terraform will show you what resources it plans to create.

    ```bash
    terraform plan
    `````

4. **Apply the configuration**:
This command will build and deploy all the resources on AWS. Type yes when prompted.

    ```bash
    terraform apply
    ```

5. **Destroy the Infrastructure**:
When you are finished and want to tear down all the resources to avoid further costs, run:

    ```bash
    terraform destroy
    ```

    Type ``yes`` when prompted. This will remove all the AWS resources created by this configuration.

### Configuration Details

The main configuration variables are in variables.tf. You may want to customize these, especially the domain_name if you plan to use a custom domain for your project. If you do, you will need to manually validate the ACM certificate through DNS.
