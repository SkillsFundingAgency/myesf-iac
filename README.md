# _Manage Your Education and Skills Funding (Infrastructure)_

<img src="https://avatars.githubusercontent.com/u/9841374?s=200&v=4" align="right" alt="UK Government logo">


[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg?longCache=true&style=flat-square)](https://en.wikipedia.org/wiki/MIT_License)

This repository contains the Infrastructure as Code (IaC) templates for the Manage Your Education and Skills Funding (MYESF) project. Like many other projects within the SFA, MYESF is a cloud-based solution that is hosted on Microsoft Azure. The IaC templates in this repository are used to deploy the infrastructure components that make up the MYESF solution.

## How It Works
This repository aims to consolidate all infrastructure efforts within the MYESF project, including many legacy projects and services to assist with disaster recovery and migration efforts.  

From a DevOps point of view: we aren't specifically responsible for the development of the MYESF application, we are responsible for the creation of infrastructure that the application runs on. Therefore, whilst we could simply create the resources through the Azure portal (as has been done in the past), this repository allows for change tracking publicly.


## 🚀 Contributing

These specifications are open source and we welcome contributions. However, the technical specifications such as the app service tiers and the services being used are subject to testing and approval from architects and security teams. 

