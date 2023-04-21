#!/usr/bin/bash


# Simple script to get the cost of your subscription for the past 3 months
# You can edit the number of months.

# You gan get the cost of all subscriptions at once by using a loop.

# Set the start and end dates in YYYY-MM-DD format
endDate=$(date +%Y-%m-%d)
startDate=$(date -d "${endDate} -3 months" +%Y-%m-%d)
billingPeriod=$(date -d "${startDate}" +%Y%m)


# Set your Azure subscription ID
subscriptionId=$(az account show --query id -o tsv)
subsname=$(az account show --subscription $subscriptionId --query name -o tsv)
echo $subsname
echo $subscriptionId

# Set your authorization token
authToken=$(az account get-access-token --resource=https://management.azure.com/ --query accessToken -o tsv)


# Set the query to get the cost data
query='{
    "type": "ActualCost",
    "timeframe": "Custom",
    "timePeriod": {
        "from": "'"$startDate"'",
        "to": "'"$endDate"'"
    },
    "dataset": {
        "granularity": "Monthly",
        "aggregation": {
            "totalCost": {
                "name": "Cost",
                "function": "Sum"
            }
        },
        "grouping": [
            {
                "type": "Dimension",
                "name": "SubscriptionId"
            },
            {
                "type": "Dimension",
                "name": "BillingMonth"
            }
        ]
    }
}'

# Call the Cost Management API to get the cost data
response=$(curl -s -X POST -H "Authorization: Bearer $authToken" -H "Content-Type: application/json" -d "$query" "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.CostManagement/query?api-version=2022-10-01")


# Parse the response to get the data for each resource
resources=$(echo $response | jq -r '.properties.rows[] | @tsv')


# Print the CSV header
echo "Subscription Name, Cost, Curency, Date" > cost_az_sub_past_3_month.csv

# Loop through the resources and print the CSV row for each
while IFS=$'\t' read -r -a resource; do
    subscriptionName=$(az account show --subscription ${resource[2]} --query name -o tsv)
    echo ${resource[2]} 
    cost=${resource[0]}
    curency=${resource[4]}
    date=$(date -d "${resource[1]}" +'%B %Y')

    # Print the CSV row
    echo "$subscriptionName, $cost, $curency, $date" >> cost_az_sub_past_3_month.csv
done <<< "$resources"


