# WordPress on Google Cloud Platform with Terraform

This project uses Terraform to deploy a complete WordPress installation on Google Cloud Platform (GCP). The infrastructure consists of a Compute Engine VM for the web server and a Cloud SQL instance for the MySQL database, all within a custom VPC network.

## Architecture

* **VPC:** A custom VPC (`wordpress-vpc`) to provide an isolated network environment.
* **Subnet:** A single subnet (`wordpress-public-subnet`) within the VPC.
* **Firewall Rules:** Allows incoming HTTP (80), HTTPS (443), and SSH (22) traffic to the web server.
* **Compute Engine:** A single `e2-micro` VM instance to serve the WordPress files. It uses a startup script to install Apache, PHP, and WordPress.
* **Cloud SQL:** A managed MySQL 8.0 instance (`db-n1-standard-1`) with a private IP address, accessible only from within the VPC.

## Prerequisites

1.  **Google Cloud Platform (GCP) Account:** You need a GCP account with a project created.
2.  **gcloud CLI:** The Google Cloud command-line tool, authenticated to your account.
    * Run `gcloud auth login` and `gcloud auth application-default login`.
3.  **Terraform:** Terraform CLI (version 1.0 or later) installed on your local machine.

## ️ Configuration

1.  **Set Your Project ID:**
    Open the `variables.tf` file and update the `default` value for `project_id` with your actual GCP Project ID.

    ```terraform
    // variables.tf
    variable "project_id" {
      description = "Your GCP Project ID"
      type        = string
      default     = "your-gcp-project-id" // <-- CHANGE THIS
    }
    ```

2.  **Set the Database Password:**
    Create a new file named `terraform.tfvars` in the same directory. This file will hold your secret database password and should **not** be committed to version control (add it to `.gitignore`).

    Add the following content to `terraform.tfvars`, replacing the placeholder with a strong password:

    ```tfvars
    # terraform.tfvars
    db_password = "your-strong-database-password"
    ```

##  Deployment

1.  **Initialize Terraform:**
    This command downloads the necessary provider plugins.

    ```bash
    terraform init
    ```

2.  **Apply the Configuration:**
    This command will show you a plan of the resources to be created. Type `yes` to proceed.

    ```bash
    terraform apply
    ```

    The deployment will take about 5-10 minutes, mainly for the Cloud SQL instance to be created.

3.  **Access Your WordPress Site:**
    After the `apply` command is complete, Terraform will output the public IP address of your web server.

    ```
    Outputs:

    wordpress_vm_ip = "34.123.45.67"
    ```

    Open this IP address in your web browser. You should see the WordPress "Welcome" screen to complete the installation.

## Cleanup

To destroy all the resources created by this project and avoid incurring further costs, run the following command:

```bash
terraform destroy
```
Type `yes` when prompted to confirm the deletion.