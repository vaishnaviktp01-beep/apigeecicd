# Apigee Proxy CI/CD Pipeline

A comprehensive CI/CD pipeline for deploying Apigee proxy APIs to the eval environment using Maven and GitHub Actions.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This project provides a complete CI/CD pipeline for deploying Apigee proxy APIs with the following features:

- ✅ **Automated Build & Test**: Maven-based build with unit and integration tests
- ✅ **Continuous Deployment**: Automatic deployment to eval environment on `develop` branch push
- ✅ **Post-Deployment Verification**: Smoke tests to verify successful deployment
- ✅ **Slack Notifications**: Real-time notifications for deployment status
- ✅ **Environment Management**: Support for eval, staging, and production environments
- ✅ **Artifact Management**: Automated proxy bundle storage and archival
- ✅ **Rollback Capability**: Automatic rollback on deployment failure
- ✅ **Security Scanning**: Optional security analysis on pull requests

## 📦 Prerequisites

### Local Development

- **Java**: JDK 11 or higher
- **Maven**: 3.6.0 or higher
- **Git**: Latest version
- **Docker**: (Optional) For containerized builds

### Apigee

- **Apigee Organization**: Active Apigee Edge or Apigee Cloud account
- **Service Account**: With appropriate permissions for proxy deployment
- **Apigee Hostnames**: Valid API hostname for eval environment

### GitHub

- **Repository Access**: Push/admin permissions to the repository
- **GitHub Secrets**: Configured for Apigee credentials and notifications

## 📁 Project Structure

```
apigee-proxy-api/
├── .github/
│   └── workflows/
│       └── deploy-apigee-proxy.yml       # GitHub Actions workflow
├── src/
│   ├── main/
│   │   ├── apigee/                       # Proxy resources
│   │   │   ├── proxies/
│   │   │   ├── policies/
│   │   │   ├── targets/
│   │   │   └── resources/
│   │   └── assembly/
│   │       └── bundle.xml                # Maven assembly config
│   └── test/
│       └── java/
│           ├── SmokeTests.java           # Post-deployment tests
│           └── IntegrationTests.java     # Integration tests
├── config/
│   └── eval-config.xml                   # Eval environment config
├── scripts/
│   └── deploy.sh                         # Deployment script
├── pom.xml                               # Maven configuration
├── Dockerfile                            # Docker image definition
├── .gitignore                            # Git exclusions
├── README.md                             # This file
└── DEPLOYMENT_GUIDE.md                   # Detailed deployment guide
```

## 🚀 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/vaishnaviktp01-beep/apigeecicd.git
cd apigeecicd
```

### 2. Install Dependencies

```bash
mvn clean install
```

### 3. Configure GitHub Secrets

Navigate to your repository settings and add the following secrets under **Settings → Secrets and variables → Actions**:

| Secret Name | Description | Example |
|-------------|-------------|----------|
| `APIGEE_ORG` | Apigee organization name | `my-org` |
| `APIGEE_USERNAME` | Service account username | `my-service-account@example.com` |
| `APIGEE_PASSWORD` | Service account password | `*****` |
| `APIGEE_HOSTURL` | Apigee management API URL | `https://api.enterprise.apigee.com` |
| `APIGEE_HOSTNAME` | API proxy hostname | `api.eval.example.com` |
| `SLACK_WEBHOOK` | Slack webhook URL (optional) | `https://hooks.slack.com/...` |

### 4. Create Apigee Service Account

```bash
# Example: Creating a service account in Apigee
# Requires admin access to your Apigee organization

# Steps:
# 1. Log in to Apigee Edge or Apigee Cloud
# 2. Go to Admin → Users → + User
# 3. Enter email and password
# 4. Assign role: "Organization Administrator" or custom role with deployment permissions
# 5. Use these credentials for GitHub secrets
```

### 5. Set Up Slack Webhook (Optional)

```bash
# 1. Go to your Slack workspace settings
# 2. Create an Incoming Webhook
# 3. Copy the webhook URL
# 4. Add as SLACK_WEBHOOK secret in GitHub
```

## ⚙️ Configuration

### Maven Properties

Edit `pom.xml` to customize:

```xml
<properties>
    <proxy.name>apigee-proxy-api</proxy.name>
    <proxy.basepath>/api/v1</proxy.basepath>
    <target.name>backend</target.name>
    <apigee.maven.plugin.version>2.3.5</apigee.maven.plugin.version>
</properties>
```

### Environment Profiles

Supported Maven profiles:

```bash
# Build for eval environment
mvn clean package -Peval

# Build for staging environment
mvn clean package -Pstaging

# Build for production environment
mvn clean package -Pprod
```

### Apigee Configuration

Edit `config/eval-config.xml` to customize eval-specific settings:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<config>
    <environment>eval</environment>
    <target.url>https://backend-eval.example.com</target.url>
    <api.timeout>30000</api.timeout>
    <cache.ttl>3600</cache.ttl>
</config>
```

## �배 Deployment

### Automatic Deployment

Automatically triggered on:

1. **Push to `develop` branch** - Deploys to eval environment
2. **Push to `main` branch** - Monitored but not auto-deployed (PR only)
3. **Manual workflow dispatch** - Via GitHub Actions UI

### Manual Deployment

#### Via GitHub Actions UI

1. Navigate to **Actions** tab in repository
2. Select **Deploy Apigee Proxy to Eval** workflow
3. Click **Run workflow**
4. Select desired environment from dropdown
5. Click **Run workflow**

#### Via Command Line

```bash
# Deploy to eval
./scripts/deploy.sh eval

# Deploy with custom proxy name
./scripts/deploy.sh eval my-custom-proxy

# View deployment status
./scripts/deploy.sh status eval
```

#### Via Maven

```bash
# Build and deploy
mvn clean package apigee-enterprise:deploy \
  -Dorg=my-org \
  -Denv=eval \
  -Dapigee.username=$APIGEE_USERNAME \
  -Dapigee.password=$APIGEE_PASSWORD \
  -Dapigee.hosturl=$APIGEE_HOSTURL
```

## 📊 Monitoring & Verification

### Check Deployment Status

```bash
# View deployment history
mvn apigee-enterprise:get \
  -Dorg=my-org \
  -Denv=eval \
  -Dapigee.username=$APIGEE_USERNAME \
  -Dapigee.password=$APIGEE_PASSWORD \
  -Dapigee.hosturl=$APIGEE_HOSTURL
```

### View Workflow Logs

1. Go to **Actions** tab
2. Select workflow run
3. Click on **build-and-deploy** job
4. View detailed logs for each step

### Test Deployed API

```bash
# Run smoke tests
mvn test -Dtest=SmokeTests \
  -Dapigee.target.url=https://api.eval.example.com \
  -Dorg=my-org \
  -Denv=eval
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Maven Build Failure

**Error**: `Could not resolve dependencies`

**Solution**:
```bash
# Clear local cache and retry
mvn clean install -U
```

#### 2. Apigee Authentication Error

**Error**: `401 Unauthorized`

**Solution**:
- Verify GitHub secrets are correctly set
- Confirm Apigee credentials are valid
- Check service account has deployment permissions

```bash
# Test credentials locally
curl -u username:password https://api.enterprise.apigee.com/v1/organizations/my-org
```

#### 3. Proxy Deployment Failed

**Error**: `Deployment failed: Invalid proxy configuration`

**Solution**:
- Validate proxy configuration files
- Check policy syntax
- Verify target endpoints exist

```bash
# Validate locally
mvn apigee-enterprise:deploy -X
```

#### 4. Slack Notification Not Sent

**Error**: `Webhook URL invalid`

**Solution**:
- Verify Slack webhook URL in GitHub secrets
- Test webhook URL directly
- Check Slack workspace permissions

#### 5. Timeout Errors

**Error**: `Request timeout after 30s`

**Solution**:
- Increase timeout in workflow:
  ```yaml
  timeout-minutes: 60
  ```
- Check Apigee service status
- Verify network connectivity

### Debug Mode

Enable debug logging:

```bash
# Local Maven debug
mvn -X clean package

# GitHub Actions debug
# Set secrets:
# ACTIONS_STEP_DEBUG = true
```

### Getting Help

- Check [Apigee Documentation](https://docs.apigee.com/)
- Review [Maven Plugin Docs](https://github.com/apigee/apigee-maven-plugins)
- Open a GitHub issue in this repository

## 📚 Additional Resources

- [Apigee Edge Documentation](https://docs.apigee.com/api-platform/)
- [Maven Documentation](https://maven.apache.org/guides/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [REST API Best Practices](https://restfulapi.net/)

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Commit changes: `git commit -am 'Add new feature'`
3. Push to branch: `git push origin feature/my-feature`
4. Submit pull request

## 📝 License

MIT License - see LICENSE file for details

## 👥 Support

For issues and questions:
- Open a GitHub issue
- Contact the DevOps team
- Check the DEPLOYMENT_GUIDE.md for detailed instructions
