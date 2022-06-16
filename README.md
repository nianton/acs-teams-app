# Azure Communication Services web application

[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnianton%2Facs-teams-app%2Fmain%2Fazure.deploy.json)

This is a templated deployment of a secure Azure architecture for hosting an Azure Communications Service web application to integrate with MS Teams leveraging Bot Service.

<!-- The architecture of the solution is as depicted on the following diagram:

![Artitectural Diagram](./assets/azure-deployment-diagram1.png?raw=true) -->

## The role of each component
* **Azure Communication Services** -to provide rich communication capabilities and Teams integration
* **Web App** -public facing website
* **Azure Key Vault** responsible to securely store the secrets/credentials for the PaaS services to be access by the web applications
* **Application Insights** to provide monitoring and visibility for the health and performance of the application
* **Bot Service** to facilitate bot integration in the communication channels
* **CosmosDB Database** the NoSQL database to be used for storing chat sessions
* **Data Storage Account** the Storage Account that will contain the application data / blob files

<br>

---
Based on the template repository (**[https://github.com/nianton/bicep-starter](https://github.com/nianton/azure-naming#bicep-azure-naming)**) to get started with an bicep infrastructure-as-code project, including the azure naming module to facilitate naming conventions. 

For the full reference of the supported naming for Azure resource types, head to the main module repository: **[https://github.com/nianton/azure-naming](https://github.com/nianton/azure-naming#bicep-azure-naming-module)**