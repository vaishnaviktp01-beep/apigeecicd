# Apigee Proxy Deployment Guide

Comprehensive step-by-step guide for deploying Apigee proxies to the eval environment.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Troubleshooting](#troubleshooting)
5. [Rollback Procedures](#rollback-procedures)
6. [Monitoring](#monitoring)
7. [FAQ](#faq)

## Quick Start

For experienced users:

```bash
# Clone repository
git clone https://github.com/vaishnaviktp01-beep/apigeecicd.git
cd apigeecicd

# Set environment variables
export APIGEE_ORG=your-org
export APIGEE_USERNAME=your-username
export APIGEE_PASSWORD=your-password
export APIGEE_HOSTURL=https://api.enterprise.apigee.com

# Deploy
./scripts/deploy.sh eval
```

## Prerequisites

### System Requirements

- **Operating System**: Linux, macOS, or Windows (with WSL2)
- **Java**: JDK 11 or higher
- **Maven**: 3.6.0 or higher
- **Git**: Latest version
- **curl**: For API testing

### Software Installation

#### macOS

```bash
# Using Homebrew
brew install java11 maven git curl

# Verify installations
java -version
mvn -version
git --version
```

#### Ubuntu/Debian

```bash
# Update package manager
sudo apt-get update

# Install required packages
sudo apt-get install -y openjdk-11-jdk maven git curl

# Verify installations
java -version
mvn -version
git --version
```

#### Windows

```powershell
# Using Chocolatey
choco install openjdk11 maven git curl

# Verify installations
java -version
mvn -version
git --version
```

### Apigee Account Setup

1. **Create Apigee Account**
   - Go to [Apigee Cloud](https://cloud.google.com/apigee)
   - Create a new organization
   - Create a new environment (e.g., "eval")

2. **Create Service Account**
   ```bash
   # Using Apigee Edge
   # Admin → Users → + User
   # Email: deployment-bot@example.com
   # Password: [Generate strong password]
   # Role: Organization Administrator or custom deployment role
   ```

3. **Note Credentials**
   - Organization Name: `my-org`
   - Service Account Email: `deployment-bot@example.com`
   - Service Account Password: `[your-password]`
   - Management API URL: `https://api.enterprise.apigee.com`

## Step-by-Step Deployment

### Phase 1: Local Setup (5 minutes)

#### Step 1.1: Clone Repository

```bash
git clone https://github.com/vaishnaviktp01-beep/apigeecicd.git
cd apigeecicd

# Verify directory structure
ls -la
# Expected output:
# drwxr-xr-x  .github/
# drwxr-xr-x  src/
# drwxr-xr-x  scripts/
# drwxr-xr-x  config/
# -rw-r--r--  pom.xml
# -rw-r--r--  Dockerfile
# -rw-r--r--  .gitignore
```

#### Step 1.2: Verify Prerequisites

```bash
# Check Java installation
java -version
# Expected: Java 11 or higher

# Check Maven installation
mvn -version
# Expected: Maven 3.6.0 or higher

# Check Git installation
git --version
# Expected: Git 2.0 or higher

# Make deployment script executable
chmod +x scripts/deploy.sh
```

#### Step 1.3: Set Environment Variables

```bash
# Create .env file (for local development)
cat > .env << EOF
export APIGEE_ORG=my-org
export APIGEE_USERNAME=deployment-bot@example.com
export APIGEE_PASSWORD=your-secure-password
export APIGEE_HOSTURL=https://api.enterprise.apigee.com
export APIGEE_HOSTNAME=api.eval.example.com
EOF

# Load environment variables
source .env

# Verify variables are set
echo $APIGEE_ORG
echo $APIGEE_USERNAME
```

### Phase 2: Local Build & Test (10 minutes)

#### Step 2.1: Install Maven Dependencies

```bash
mvn clean install

# Expected output:
# [INFO] BUILD SUCCESS
# [INFO] Total time: XX.XXs
```

#### Step 2.2: Validate Proxy Structure

```bash
mvn validate

# Expected output:
# [INFO] BUILD SUCCESS
```

#### Step 2.3: Build Proxy Bundle

```bash
mvn clean package -Dorg=$APIGEE_ORG -Denv=eval

# Expected output:
# [INFO] Building zip: target/apigee-proxy-api.zip
# [INFO] BUILD SUCCESS

# Verify artifacts
ls -lh target/*.zip
```

#### Step 2.4: Run Unit Tests

```bash
mvn test

# Expected output:
# [INFO] Tests run: X, Failures: 0, Errors: 0
# [INFO] BUILD SUCCESS
```

### Phase 3: GitHub Configuration (5 minutes)

#### Step 3.1: Access Repository Settings

1. Go to: https://github.com/vaishnaviktp01-beep/apigeecicd
2. Click **Settings** tab
3. Select **Secrets and variables** → **Actions**

#### Step 3.2: Add Required Secrets

Create the following secrets:

| Secret Name | Value |
|-------------|-------|
| APIGEE_ORG | my-org |
| APIGEE_USERNAME | deployment-bot@example.com |
| APIGEE_PASSWORD | [secure-password] |
| APIGEE_HOSTURL | https://api.enterprise.apigee.com |
| APIGEE_HOSTNAME | api.eval.example.com |
| SLACK_WEBHOOK | https://hooks.slack.com/... (optional) |

**Steps to Add Secret:**

1. Click **New repository secret**
2. Enter Name: `APIGEE_ORG`
3. Enter Value: `my-org`
4. Click **Add secret**
5. Repeat for each secret

### Phase 4: Deploy to Eval Environment (5-10 minutes)

#### Option A: Using GitHub Actions UI (Recommended)

1. Go to **Actions** tab
2. Select **Deploy Apigee Proxy to Eval** workflow
3. Click **Run workflow**
4. Select branch: `develop`
5. (Optional) Select environment: `eval`
6. Click **Run workflow**
7. Monitor execution in real-time

#### Option B: Using Deployment Script

```bash
# Deploy to eval environment
./scripts/deploy.sh eval

# Expected output:
# [INFO] Starting Apigee Proxy Deployment
# [SUCCESS] Proxy deployed successfully
# [SUCCESS] Smoke tests passed
```

#### Option C: Using Maven Directly

```bash
mvn apigee-enterprise:deploy \
  -Dorg=$APIGEE_ORG \
  -Denv=eval \
  -Dapigee.username=$APIGEE_USERNAME \
  -Dapigee.password=$APIGEE_PASSWORD \
  -Dapigee.hosturl=$APIGEE_HOSTURL

# Expected output:
# [INFO] Deploying proxy: apigee-proxy-api to environment: eval
# [INFO] Deployment succeeded
```

### Phase 5: Verification (5 minutes)

#### Step 5.1: Check Deployment Status

```bash
# View deployment details
mvn apigee-enterprise:get \
  -Dorg=$APIGEE_ORG \
  -Denv=eval \
  -Dapigee.username=$APIGEE_USERNAME \
  -Dapigee.password=$APIGEE_PASSWORD \
  -Dapigee.hosturl=$APIGEE_HOSTURL
```

#### Step 5.2: Test API Endpoint

```bash
# Health check
curl -X GET "https://api.eval.example.com/health" \
  -H "Content-Type: application/json" \
  -v

# Expected: 200 OK

# Test API endpoint
curl -X GET "https://api.eval.example.com/api/v1/status" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -v

# Expected: 200 OK with response body
```

#### Step 5.3: Run Smoke Tests

```bash
mvn test -Dtest=SmokeTests \
  -Dapigee.target.url=https://api.eval.example.com \
  -Dorg=$APIGEE_ORG \
  -Denv=eval

# Expected output:
# [INFO] Tests run: 10, Failures: 0, Errors: 0
# [INFO] BUILD SUCCESS
```

#### Step 5.4: Review Deployment Logs

1. Go to **Actions** tab
2. Select workflow run
3. Click **build-and-deploy** job
4. Review logs for each step
5. Check **Generate Deployment Report** step

## Troubleshooting

### Issue 1: "Maven is not installed"

**Error Message:**
```
mvn: command not found
```

**Solution:**
```bash
# Install Maven
brew install maven          # macOS
sudo apt-get install maven  # Ubuntu/Debian
choco install maven         # Windows

# Verify installation
mvn -version
```

### Issue 2: "401 Unauthorized" from Apigee

**Error Message:**
```
[ERROR] org.apache.maven.plugin.MojoExecutionException:
Authentication failure for user: deployment-bot@example.com
```

**Solution:**
```bash
# Verify credentials
echo $APIGEE_USERNAME
echo $APIGEE_PASSWORD

# Test authentication
curl -u $APIGEE_USERNAME:$APIGEE_PASSWORD \
  https://api.enterprise.apigee.com/v1/organizations/$APIGEE_ORG

# If still failing:
# 1. Check password for special characters
# 2. Verify service account exists in Apigee
# 3. Check service account has appropriate permissions
# 4. Reset password in Apigee UI
```

### Issue 3: "Deployment timeout"

**Error Message:**
```
[ERROR] Request timeout after 30s
```

**Solution:**
```bash
# Check network connectivity
ping api.enterprise.apigee.com

# Increase timeout in .github/workflows/deploy-apigee-proxy.yml
# Change timeout-minutes: 10 to timeout-minutes: 60

# Check Apigee service status
# https://status.apigee.com/
```

### Issue 4: "Target endpoint not found"

**Error Message:**
```
[ERROR] Target endpoint 'backend' not configured
```

**Solution:**
```bash
# Verify target configuration
cat src/main/apigee/targets/*.xml

# Check config/eval-config.xml
cat config/eval-config.xml

# Verify backend URL is accessible
curl -v https://backend-eval.example.com/health
```

### Issue 5: "Smoke tests failed"

**Error Message:**
```
[ERROR] SmokeTests FAILED
```

**Solution:**
```bash
# Run tests with verbose output
mvn test -Dtest=SmokeTests -X

# Check if proxy is deployed
mvn apigee-enterprise:get ...

# Test endpoint manually
curl -X GET "https://api.eval.example.com/health" -v

# Check proxy policies for errors
# Review trace in Apigee UI
```

## Rollback Procedures

### Rollback to Previous Deployment

```bash
# Option 1: Redeploy previous revision
mvn apigee-enterprise:deploy \
  -Dorg=$APIGEE_ORG \
  -Denv=eval \
  -Drevision=2 \
  -Dapigee.username=$APIGEE_USERNAME \
  -Dapigee.password=$APIGEE_PASSWORD \
  -Dapigee.hosturl=$APIGEE_HOSTURL

# Option 2: Undeploy current version
mvn apigee-enterprise:undeploy \
  -Dorg=$APIGEE_ORG \
  -Denv=eval \
  -Dapigee.username=$APIGEE_USERNAME \
  -Dapigee.password=$APIGEE_PASSWORD \
  -Dapigee.hosturl=$APIGEE_HOSTURL

# Option 3: Deploy from git history
git checkout [previous-commit]
./scripts/deploy.sh eval
```

## Monitoring

### Check Deployment Status

```bash
# View deployment history
mvn apigee-enterprise:get \
  -Dorg=$APIGEE_ORG \
  -Denv=eval \
  -Dapigee.username=$APIGEE_USERNAME \
  -Dapigee.password=$APIGEE_PASSWORD \
  -Dapigee.hosturl=$APIGEE_HOSTURL
```

### View Metrics

1. Log into Apigee Console
2. Navigate to **Proxies** → **Your Proxy**
3. Select **Environment: eval**
4. View **Analytics**
5. Check **Message Count**, **Average Response Time**, **Error Rate**

### Set Up Alerts

1. In Apigee Console: **Admin** → **Alerts**
2. Create alert for:
   - High error rate (> 5%)
   - High response time (> 2000ms)
   - Deployment failures

## FAQ

### Q: How do I deploy to staging or production?

**A:** Use the same process but change the environment:

```bash
./scripts/deploy.sh staging
./scripts/deploy.sh prod
```

### Q: How do I add custom policies?

**A:** Add policy files to `src/main/apigee/policies/` and reference them in proxy configuration.

### Q: Can I deploy without GitHub Actions?

**A:** Yes, use the local deployment script or Maven directly:

```bash
./scripts/deploy.sh eval
```

### Q: How do I handle authentication?

**A:** Edit `config/eval-config.xml` and proxy flow policies.

### Q: What's the deployment frequency limit?

**A:** No limit. Deploy as often as needed. Each deployment creates a new revision.

### Q: How do I view deployment logs?

**A:** Logs are stored in `deployment.log` and GitHub Actions logs.

### Q: How do I add custom validation?

**A:** Add Java tests to `src/test/java/` or update `SmokeTests.java`.

---

**Last Updated**: 2024
**Document Version**: 1.0
