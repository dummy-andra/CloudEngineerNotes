The default API version used by the az consumption CLI 

```bash
az consumption usage list
Command group 'consumption' is in preview and under development. Reference and support levels: https://aka.ms/CLI_refstatus
(400) Subscription scope usage is not supported for current api version. Please use api version after 2019-10-01
```



**Root Cause**

- The error is being caused by the fact that the current API version being used does not support subscription scope usage. This means that the code is trying to access usage details at the subscription level, but the API version being used does not support this functionality. The error message suggests using an API version after 2019-10-01, which likely includes support for subscription level usage details. 

- When you execute the `az consumption usage list` command, the Azure CLI sends a request to the Azure Consumption API to retrieve the usage details for your Azure subscription. By default, the Azure CLI uses the API endpoint `https://management.azure.com/providers/Microsoft.Consumption/usageDetails` to retrieve this information.

  

- The default API version used in the code is "2021-10-01". This can be seen in the build_list_request function where the api_version parameter is set to "2021-10-01" by default if it is not provided by the caller. se herehttps://github.com/Azure/azure-sdk-for-python/blob/main/sdk/consumption/azure-mgmt-consumption/azure/mgmt/consumption/operations/_usage_details_operations.py

- In the case of the `az consumption CLI`, it appears that the default API version used is `2018-01-31`.





## Full Troubleshooting Repot



- [ ] ###### Get the API used by az CLI that you use in your terminal/script 

- **When you run the `az consumption usage list` command with the` --debug` option, it will display a lot of output that includes the API request and response details.**
- Look for the line that starts with ==> REQUEST in the output, which shows the HTTP request that was sent to the consumption usage API. The request URL will contain the `api-version` parameter followed by the `API version being used`.



```bash
az consumption usage list  --debug
[...]
msrest.http_logger: Request method: 'GET'
msrest.http_logger: Request headers:
msrest.http_logger:   'Accept': 'application/json'
msrest.http_logger:   'Content-Type': 'application/json; charset=utf-8'
msrest.http_logger:   'accept-language': 'en-US'
msrest.http_logger:   'User-Agent': ... msrest/xxx msrest_azure/xxx azure-mgmt-consumption/xxx Azure-SDK-For-Python AZURECLI/2.47.0 (DEB)'
msrest.http_logger: Request body:
[...]
msrest.universal_http: Evaluate proxies against ENV settings: True
urllib3.connectionpool: Starting new HTTPS connection (1): management.azure.com:443
urllib3.connectionpool: https://management.azure.com:443 "GET /subscriptions/xxxx-xxxxx-xxxx-xxxx/providers/Microsoft.Consumption/usageDetails?api-version=2018-01-31 HTTP/1.1" 400 194
msrest.http_logger: Response status: 400

cli.azure.cli.core.azclierror: Traceback (most recent call last):
   File "/opt/az/lib/python3.10/site-packages/azure/cli/core/commands/**__init__**.py", line 705, in _run_job
   result = transform_op(result)
 File "/opt/az/lib/python3.10/site-packages/azure/cli/command_modules/consumption/_transformers.py", line 20, in transform_usage_list_output
  return [transform_usage_output(item) for item in result]
 File "/opt/az/lib/python3.10/site-packages/azure/cli/command_modules/consumption/_transformers.py", line 20, in <listcomp>
  return [transform_usage_output(item) for item in result]
 File "/opt/az/lib/python3.10/site-packages/msrest/paging.py", line 143, in **__next__**
  self.advance_page()
 File "/opt/az/lib/python3.10/site-packages/msrest/paging.py", line 129, in advance_page
  self._response = self._get_next(self.next_link)
 File "/opt/az/lib/python3.10/site-packages/azure/mgmt/consumption/operations/usage_details_operations.py", line 116, in internal_paging
  raise models.ErrorResponseException(self._deserialize, response)

azure.mgmt.consumption.models.error_response.ErrorResponseException: 
(400) Subscription scope usage is not supported for current api version. Please use api version after 2019-10-01


```



**Here's a brief breakdown of what's happening in `cli.azure.cli.core.azclierror: Traceback`:**

- The first line shows the file path to a script within the Azure CLI package: `/opt/az/lib/python3.10/site-packages/azure/cli/core/commands/__init__.py`.

- Within this file, on line 705, there is a function called `_run_job` that is being called.

  - [azure-cli/__init__.py at dev · Azure/azure-cli (github.com)](https://github.com/Azure/azure-cli/blob/dev/src/azure-cli-core/azure/cli/core/commands/__init__.py) --> is defined at line 694 actualy ` def _run_job`

  - line 703-705

    - ```python
                  transform_op = cmd_copy.command_kwargs.get('transform', None)
                  if transform_op:
                      result = transform_op(result)
      ```

  - The `transform_op` function is being applied to the `result` object, which is the output of the command being executed.

- The `transform_usage_list_output` function in the `azure/cli/command_modules/consumption/_transformers.py` file  is being called to transform the output of the `list`  method of the `UsageDetailsOperations` class defined in the `azure.mgmt.consumption.operations.usage_details_operations` module, into a format that can be more easily consumed by the Azure CLI. This function takes the `result` object, which is the output of the `list_usage_details` method, and applies the `transform_usage_output` function to each item in the list.

  - [azure-cli/_transformers.py at dev · Azure/azure-cli (github.com)](https://github.com/Azure/azure-cli/blob/dev/src/azure-cli/azure/cli/command_modules/consumption/_transformers.py)

  - ```python
    def transform_usage_list_output(result):
        return [transform_usage_output(item) for item in result]
    ```

  - Specifically, the `transform_usage_list_output` function is returning a list of usage details by applying the `transform_usage_output` function to each item in the `result` list.

  - This is being done through a list comprehension: `[transform_usage_output(item) for item in result]`.

  

- The `__next__` method of a `Paged` object (in `msrest/paging.py`) is being called to retrieve the next page of results.

  - [msrest-for-python/paging.py at master · Azure/msrest-for-python (github.com)](https://github.com/Azure/msrest-for-python/blob/master/msrest/paging.py)

  - The `msrest` package facilitates the communication between these two modules `azure/cli/command_modules/consumption/_transformers.py` and `azure.mgmt.consumption.operations.usage_details_operations`  by handling the pagination of the `result` object. When the `Paged` object is iterated over, `msrest` retrieves the next page of results using the `_get_next` method of the `UsageDetailsOperations` class defined in `azure.mgmt.consumption.operations.usage_details_operations`. The `msrest` package then passes the new page of results to the `transform_usage_list_output` function for transformation. This process continues until all pages of results have been retrieved and transformed.

  - ```python
        def __next__(self):
            """Iterate through responses."""
            # Storing the list iterator might work out better, but there's no
            # guarantee that some code won't replace the list entirely with a copy,
            # invalidating an list iterator that might be saved between iterations.
            if self.current_page and self._current_page_iter_index < len(self.current_page):
                response = self.current_page[self._current_page_iter_index]
                self._current_page_iter_index += 1
                return response
            else:
                self.advance_page()
                return self.__next__()
    
        next = __next__  # Python 2 compatibility.
    ```

  - This method calls `advance_page` to retrieve the next page of results and sets the `_response` attribute to the response from the API.

    - ```python
          def advance_page(self):
              # type: () -> List[Model]
              """Force moving the cursor to the next azure call.
              This method is for advanced usage, iterator protocol is preferred.
              :raises: StopIteration if no further page
              :return: The current page list
              :rtype: list
              """
              if self.next_link is None:
                  raise StopIteration("End of paging")
              self._current_page_iter_index = 0
              self._response = self._get_next(self.next_link)
              self._derserializer(self, self._response)
              return self.current_page
      ```

- The `get_next` method of the `UsageDetailsOperations` class in `azure/mgmt/consumption/operations/usage_details_operations.py` is being called to retrieve the next page of results.

  - [azure-sdk-for-python/_usage_details_operations.py at main · Azure/azure-sdk-for-python (github.com)](https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/consumption/azure-mgmt-consumption/azure/mgmt/consumption/operations/_usage_details_operations.py)

  - ```python
            def get_next(next_link=None):
                request = prepare_request(next_link)
    
                pipeline_response: PipelineResponse = self._client._pipeline.run(  # pylint: disable=protected-access
                    request, stream=False, **kwargs
                )
                response = pipeline_response.http_response
    
                if response.status_code not in [200, 204]:
                    map_error(status_code=response.status_code, response=response, error_map=error_map)
                    error = self._deserialize.failsafe_deserialize(_models.ErrorResponse, pipeline_response)
                    raise HttpResponseError(response=response, model=error, error_format=ARMErrorFormat)
    
                return pipeline_response
    
            return ItemPaged(get_next, extract_data)
    ```



> The Azure CLI is built with modularity in mind, which means that different functionality is separated into different modules. The `azure-cli` module is responsible for providing the command-line interface, and the `azure-cli-core` module provides the core functionality that underlies the Azure CLI.
>
> The `azure-cli` module uses the `azure-mgmt-consumption` package to communicate with the Azure Consumption API. The `azure-mgmt-consumption` package is generated from the Consumption API's Swagger specification, which defines the available operations and their parameters.
>
> The `azure-cli` module determines the version of the API to use by looking at the version specified in the Swagger specification. If the version specified in the Swagger specification is different from the version specified in the query string of the request, then the Azure CLI will use the version specified in the Swagger specification.





# What to use instead of CLI



1.  **Call the Cost Consumption API to get usageDetails**
   1. [Usage Details - List - REST API (Azure Consumption) | Microsoft Learn](https://learn.microsoft.com/en-us/rest/api/consumption/usage-details/list?tabs=HTTP)

```

# Set your Azure subscription ID
subscriptionId=$(az account show --query id -o tsv)

# Set your authorization token
authToken=$(az account get-access-token --resource=https://management.azure.com/ --query accessToken -o tsv)

# Set the start and end dates in YYYY-MM-DD format
startDate="2023-04-01"
endDate="2023-04-17"

# Call the Cost Consumption API to get usageDetails
usage=$(curl -s -X GET -H "Authorization: Bearer $authToken" -H "Content-Type: application/json" "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Consumption/usageDetails?api-version=2023-03-01&$filter=properties/usageEnd ge '${startDate}' AND properties/usageEnd le '${endDate}'")

echo "${usage}" | jq -r '.value[]'


```



2. **Call the Cost Management API to get the cost data**
   1. [Query - Usage - REST API (Azure Cost Management) | Microsoft Learn](https://learn.microsoft.com/en-us/rest/api/cost-management/query/usage?tabs=HTTP)

```
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
   echo $response | jq -r '.properties.rows[] 
```

