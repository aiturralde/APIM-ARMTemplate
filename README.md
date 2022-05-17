# About the project

This was a sample delivered to a customer so that he could deploy an API Management instance with additional resources they need, such as:

- Application Insights
- VNET


## How to deploy

First you will need a resource group, something like this:
*
```powershell
az group create --name exampleRG --location eastus
```

After this you can deploy de Bicep template based on the parameters file

```powershell
az deployment group create --resource-group exampleRG --template-file main.bicep --parameters main.parameters.json
```