# AWS Information Collection Script

This Bash script is designed to collect various information related to an AWS (Amazon Web Services) environment. It retrieves data such as AWS Organization details, billing information, enabled services, workloads in the root account, AWS Identity Center status, AWS Service Control Policies (SCPs), AWS Marketplace listings, and cost allocation tags.

## Prerequisites

Before using this script, ensure the following prerequisites are met:

- **AWS CLI**: The AWS Command Line Interface (CLI) must be installed and configured with appropriate permissions.
- **jq**: A lightweight and flexible command-line JSON processor used for parsing JSON data. It must be installed on the system where the script will be executed.

## Usage

1. Clone or download the script from the repository.
2. Make the script executable using the following command:
    ```bash
    chmod +x aws_info_collection.sh
    ```
3. Execute the script:
    ```bash
    ./aws_info_collection.sh
    ```

## Functionality

### Organization Details
- Checks if AWS Organization is enabled.
- Lists the number of accounts in the AWS organization.
- Checks for any account with a bill above $10,000 in the last month.

### Workloads
- Checks for various workloads in the master payer account, including EC2 instances, RDS instances, EKS clusters, ECS clusters, and API Gateway instances.

### Support Plan
- Determines the level of AWS Support plan for the account (Basic, Business, or Enterprise).

### AWS Identity Center
- Checks if AWS Identity Center is enabled.

### Service Control Policies (SCPs)
- Lists AWS Service Control Policies (SCPs) if any are defined.

### AWS Marketplace Listings
- Checks for active AWS Marketplace listings.

### Cost Allocation Tags
- Checks if cost allocation tags are enabled and lists the tags.

## Output
The script outputs the collected information to the terminal.

## Author
[Kadircan KAYA] - [https://www.linkedin.com/in/kadircan-kaya/]

