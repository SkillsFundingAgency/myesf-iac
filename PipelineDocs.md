## Pipeline draft
This will be a release pipeline in Azure DevOps, as such we have one pipeline but take in arguments for any variables that change between environments. The pipeline will be triggered by a commit to the master branch of the repository. The pipeline will have the following stages:

### Production environment/OAT change suspension
Prevent any deletion or modification of resources without manual intervention. This is to prevent accidental deletion of resources in the production environment. This stage will be manual and will require a user to approve the deployment to the production environment.

### Parallel runs
There are multiple steps in the pipeline that can run in parallel. This will speed up the pipeline and reduce the time it takes to deploy the application.

## Steps

### 1. Build solution artifacts AND deploy/update 
These two stages will run in parallel as they are both time consuming, but arguably building solution artifacts takes the most CPU time - meanwhile most of the infrastructure deployment is simply waiting for the Azure API to respond (excluding the fairly quick transpilation of Bicep to ARM). The build solution artifacts stage will build the solution and create the artifacts that will be deployed. The deploy/update stage will deploy the artifacts to the appropriate environment.

#### Build solution artifacts
1. Checkout repository pds-skillsfundingservice
2. Powershell: run `SetVersionNumbers.ps1` which configures the version numbers of any projects in the solution. Use `-Verbose` as we want to see the output of the script.
3. NuGET restore (**from internal feed**) - this will restore all the NuGET packages that are required for the solution. There are a number of backend dependencies that are pulled from the internal feed in the build process. If this isn't done, the build will fail.
4. Embed all private tokens and secret keys into configuration files globally (use selector `**/*.config **/*.wadcfgx **/*.cscfg`). Auto encoding. Error out if a variable is missing. Doing this prevents service disruption if a secret key is missing. Token suffix is `__` and prefix is `__` (e.g. `__MySecretKey__`).
5. Publish the solution Using Visual Studio 2022 (or 2017 if this fails) - this will create the artifacts that will be deployed. The artifacts will be published to the `$(build.artifactstagingdirectory)\ProviderDigitalServices.Azure.Deploy`. The following parameters need to be added to MSBuild:
    * Platform: $(BuildPlatform) 
    * Configuration: $(BuildConfiguration)
    * MSBuild x64 (currently the build agent is x86, we don't want to use the x86 version of MSBuild)
    * /m /t:Publish /p:PublishDir="$(build.artifactstagingdirectory)\ProviderDigitalServices.Azure.Deploy"
    * /m has been added to the MSBuild arguments to allow for parallel builds. This will speed up the build process.

#### Deploy/update infrastructure
1. Checkout this repository
2. Use Azure CLI to deploy AppService to correct infrastructure

### 2. Deploy to environment and perform tests
Steps 1a and 1b will run in parallel. The deployment to the environment will be done first, followed by the tests. The tests will be run on the deployed application.  

1a. Deploy artifacts in publish directory generated from build step: `$(build.artifactstagingdirectory)\ProviderDigitalServices.Azure.Deploy\ProviderDigitalServices.Azure.Deploy.cspkg` and `$(build.artifactstagingdirectory)\ProviderDigitalServices.Azure.Deploy\ServiceConfiguration.$(BuildConfiguration).cscfg` into the lot that isn't active. The deployment label needs to be $(Build.BuildNumber). Force upgrade and allow upgrade. .NET 4.8 is the runtime stack.  

1b. Run tests:
```yaml
steps:
- task: VSTest@2
  displayName: 'Run Integration Tests'
  inputs:
    testAssemblyVer2: |
     **\*Tests.dll
     !**\*TestAdapter.dll
     !**\obj\**
     !**\packages\**
    testFiltercriteria: 'TestCategory=Integration'
    vsTestVersion: 15.0
    runSettingsFile: CodeCoverage.runsettings
    codeCoverageEnabled: true
    testRunTitle: 'Dev CD to DEV Integration Tests'
    platform: '$(BuildPlatform)'
    configuration: '$(BuildConfiguration)'
    rerunFailedTests: true
- task: VSTest@2
  displayName: 'Run Smoke Tests'
  inputs:
    testAssemblyVer2: |
     **\*Tests.dll
     !**\*TestAdapter.dll
     !**\obj\**
     !**\packages\**
    testFiltercriteria: 'TestCategory=Smoke'
    uiTests: true
    vsTestVersion: 15.0
    runSettingsFile: CodeCoverage.runsettings
    runInParallel: false
    codeCoverageEnabled: false
    testRunTitle: 'Dev CD to DEV Smoke Tests'
    platform: '$(BuildPlatform)'
    configuration: '$(BuildConfiguration)'
    rerunFailedTests: true
- task: VSTest@2
  displayName: 'Run Regression Tests'
  inputs:
    testAssemblyVer2: |
     **\*Tests.dll
     !**\*TestAdapter.dll
     !**\obj\**
     !**\packages\**
    testFiltercriteria: 'TestCategory=Regression'
    uiTests: true
    vsTestVersion: 15.0
    runSettingsFile: CodeCoverage.runsettings
    runInParallel: false
    codeCoverageEnabled: false
    testRunTitle: 'Dev CD to DEV Regression Tests'
    platform: '$(BuildPlatform)'
    configuration: '$(BuildConfiguration)'
    failOnMinTestsNotRun: false
    rerunFailedTests: true
```

2. If all tests are successful OR the ignore test results value is set, swap the slots. This will make the new deployment the active deployment. 

### 3. Additional tests and mock deployment (for environments lower than OAT)
1. Build `SkillsFundingService/Mocks/Mock.Web/Mock.Web.csproj`. Clean the solution before building. `/m /t:Package /p:PackageLocation="$(build.artifactstagingdirectory)\Mock.Web\Mock.Web.zip"`. $(BuildPlatform) and $(BuildConfiguration) are the parameters.
2. Deploy to app service `pds-mocks-$(BuildConfiguration)`. There is no slot for the mock deployment. The deployment label needs to be $(Build.BuildNumber). Force upgrade and allow upgrade. .NET 4.8 is the runtime stack. See `$(build.artifactstagingdirectory)\Mock.Web\Mock.Web.zip`

