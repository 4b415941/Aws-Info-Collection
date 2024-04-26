#!/bin/bash

echo "Collecting information from AWS..."

# Function to check if a workload exists
check_workload() {
    local service="$1"
    local label="$2"
    if aws "$service" "$3" \
        --query "$4" \
        --output text | grep -q "$5"; then
        echo "Yes, there are $label instances running in the root account."
        workload_found=true
    fi
}

# Function to check if AWS Support Plan is enabled
check_support_plan() {
    if aws support describe-trusted-advisor-checks \
        --language en &> /dev/null; then
        echo "The account is likely on the Business or Enterprise support plan."
    else
        error_message=$(aws support describe-trusted-advisor-checks \
            --language en 2>&1)
        if [[ "$error_message" == *"SubscriptionRequiredException"* ]]; then
            echo "The account is likely on the Basic support plan."
        else
            echo "Unable to determine the support plan due to an unexpected error:"
            echo "$error_message"
        fi
    fi
}

# Check if AWS Organization is enabled
if aws organizations describe-organization \
    --query 'Organization' &> /dev/null; then
    echo "AWS Organization is enabled."

    # How many accounts are there in the AWS organization?
    echo "Number of accounts in the AWS organization:"
    aws organizations list-accounts \
        --query 'Accounts[*].Id' \
        --output text | wc -w

    # Does any account have a bill above $10,000 in the last month?
    echo "Checking if any account has a bill above 10,000 in the last month:"
    start_date=$(date -d "-1 month -$(($(date +%d)-1)) days" +%Y-%m-%d)
    end_date=$(date -d "-$(date +%d) days" +%Y-%m-%d)
    accounts_over_10k=$(aws ce get-cost-and-usage \
        --time-period Start="$start_date",End="$end_date" \
        --granularity MONTHLY \
        --metrics "UnblendedCost" \
        --group-by Type=DIMENSION,Key=LINKED_ACCOUNT \
        --output json | jq -r '.ResultsByTime[].Groups[] | select((.Metrics.UnblendedCost.Amount | tonumber) > 10000) | .Keys[]')
    if [ -z "$accounts_over_10k" ]; then
        echo "No account above 10K monthly."
    else
        echo "Accounts with a bill over 10,000 in the last month: $accounts_over_10k"
    fi

    # Confirming the customer has an AWS Org
    echo "Customer has AWS Organization."

    # List all the AWS Org services that are enabled
    echo "List of enabled AWS Org services:"
    aws organizations list-aws-service-access-for-organization \
        --query 'EnabledServicePrincipals[*].ServicePrincipal' \
        --output table

    echo "Checking for workloads in the master payer account:"
    workload_found=false

    # Check for various workloads
    check_workload "ec2" "EC2 instances" "describe-instances" \
        "Reservations[*].Instances[*].InstanceId" "i-"
    check_workload "rds" "RDS instances" "describe-db-instances" \
        "DBInstances[*].DBInstanceIdentifier" "db-"
    check_workload "eks" "EKS clusters" "list-clusters" \
        "clusters" "."
    check_workload "ecs" "ECS clusters" "list-clusters" \
        "clusterArns" "cluster"
    check_workload "apigateway" "API Gateway instances" "get-rest-apis" \
        "items[*].id" ".*"

    # If no workloads are found, then output the message
    if [ "$workload_found" = false ]; then
        echo "No workloads detected in the root account."
    fi

    # What level of AWS Support does the account have?
    echo "AWS Support Plan for the account:"
    check_support_plan

else
    echo "AWS Organization is not enabled."
    echo "Customer does not have AWS Organization and will need a new MPA."
fi

# Check for AWS Identity Center
echo "Checking for AWS Identity Center:"
identity_center_instances=$(aws sso-admin list-instances \
    --query 'Instances' \
    --output json)
if [ "$identity_center_instances" != "[]" ]; then
    echo "Yes, AWS Identity Center is enabled."
else
    echo "No, AWS Identity Center is not enabled."
fi

# Check for AWS SCPs
echo "Checking for AWS SCPs:"
aws organizations list-policies --filter "SERVICE_CONTROL_POLICY" \
    --query 'Policies' \
    --output table

# Check for AWS Marketplace listings
echo "Checking for AWS Marketplace listings:"
start_date=$(date -d "-1 month -$(($(date +%d)-1)) days" +%Y-%m-%d)
end_date=$(date -d "-$(date +%d) days" +%Y-%m-%d)
filter_json='{"Dimensions": {"Key": "RECORD_TYPE", "Values": ["Marketplace"]}}'
filter_file=$(mktemp)
echo "$filter_json" > "$filter_file"
result=$(aws ce get-cost-and-usage \
    --time-period Start="$start_date",End="$end_date" \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --filter "file://$filter_file" \
    --output json)
rm "$filter_file"
if echo "$result" | jq -e '.ResultsByTime[].Groups[] | select(.Metrics.UnblendedCost.Amount | tonumber > 0)' &> /dev/null; then
    echo "Active AWS Marketplace listing found."
else
    echo "No marketplace listing found."
fi

# Check for cost allocation tags
echo "Checking for cost allocation tags:"
cost_allocation_tags=$(aws ce list-cost-allocation-tags \
    --query 'CostAllocationTags[*].Key' \
    --output json)
if [ -z "$cost_allocation_tags" ] || [ "$cost_allocation_tags" == "[]" ]; then
    echo "Cost allocation tags are not enabled or no tags are set."
else
    echo "Cost allocation tags are enabled."
fi

echo "Information gathering complete."
