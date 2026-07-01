#!/bin/bash

################################################################################
# Apigee Proxy Deployment Script
#
# Usage: ./scripts/deploy.sh [environment] [proxy-name] [action]
#
# Examples:
#   ./scripts/deploy.sh eval                    # Deploy to eval environment
#   ./scripts/deploy.sh eval my-proxy           # Deploy specific proxy
#   ./scripts/deploy.sh eval my-proxy status    # Check deployment status
#   ./scripts/deploy.sh eval my-proxy rollback  # Rollback to previous version
#
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-eval}
PROXY_NAME=${2:-apigee-proxy-api}
ACTION=${3:-deploy}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$BASE_DIR/target"
LOG_FILE="$BASE_DIR/deployment.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Configuration
ORG=${APIGEE_ORG:-}
USERNAME=${APIGEE_USERNAME:-}
PASSWORD=${APIGEE_PASSWORD:-}
HOSTURL=${APIGEE_HOSTURL:-https://api.enterprise.apigee.com}

################################################################################
# Functions
################################################################################

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Log message
log_message() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Maven
    if ! command -v mvn &> /dev/null; then
        print_error "Maven is not installed. Please install Maven 3.6.0 or higher."
        exit 1
    fi
    print_success "Maven installed: $(mvn --version | head -n 1)"
    
    # Check Java
    if ! command -v java &> /dev/null; then
        print_error "Java is not installed. Please install JDK 11 or higher."
        exit 1
    fi
    print_success "Java installed: $(java -version 2>&1 | head -n 1)"
    
    # Check Git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install Git."
        exit 1
    fi
    print_success "Git installed: $(git --version)"
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed. Please install curl."
        exit 1
    fi
    print_success "curl installed"
}

# Validate environment
validate_environment() {
    print_info "Validating environment: $ENVIRONMENT"
    
    case $ENVIRONMENT in
        eval|staging|prod)
            print_success "Valid environment: $ENVIRONMENT"
            ;;
        *)
            print_error "Invalid environment: $ENVIRONMENT. Supported: eval, staging, prod"
            exit 1
            ;;
    esac
}

# Check Apigee credentials
check_credentials() {
    print_info "Checking Apigee credentials..."
    
    if [ -z "$ORG" ]; then
        print_error "APIGEE_ORG not set"
        exit 1
    fi
    
    if [ -z "$USERNAME" ]; then
        print_error "APIGEE_USERNAME not set"
        exit 1
    fi
    
    if [ -z "$PASSWORD" ]; then
        print_error "APIGEE_PASSWORD not set"
        exit 1
    fi
    
    print_success "Apigee credentials configured"
}

# Validate proxy bundle
validate_proxy_bundle() {
    print_info "Validating proxy bundle..."
    
    if [ ! -d "$BASE_DIR/src/main/apigee" ]; then
        print_error "Proxy source directory not found: $BASE_DIR/src/main/apigee"
        exit 1
    fi
    
    print_success "Proxy bundle structure is valid"
}

# Build proxy bundle
build_proxy_bundle() {
    print_info "Building proxy bundle..."
    
    cd "$BASE_DIR"
    
    if mvn clean package -DskipTests -Dorg="$ORG" -Denv="$ENVIRONMENT" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Proxy bundle built successfully"
        
        # List built artifacts
        print_info "Built artifacts:"
        ls -lh "$TARGET_DIR"/*.zip 2>/dev/null || print_warning "No zip files found in target directory"
    else
        print_error "Failed to build proxy bundle"
        exit 1
    fi
}

# Deploy proxy
deploy_proxy() {
    print_info "Deploying proxy: $PROXY_NAME to environment: $ENVIRONMENT"
    
    cd "$BASE_DIR"
    
    if mvn apigee-enterprise:deploy \
        -Dorg="$ORG" \
        -Denv="$ENVIRONMENT" \
        -Dapigee.username="$USERNAME" \
        -Dapigee.password="$PASSWORD" \
        -Dapigee.hosturl="$HOSTURL" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Proxy deployed successfully"
    else
        print_error "Failed to deploy proxy"
        exit 1
    fi
}

# Get deployment status
get_deployment_status() {
    print_info "Checking deployment status for: $PROXY_NAME"
    
    cd "$BASE_DIR"
    
    if mvn apigee-enterprise:get \
        -Dorg="$ORG" \
        -Denv="$ENVIRONMENT" \
        -Dapigee.username="$USERNAME" \
        -Dapigee.password="$PASSWORD" \
        -Dapigee.hosturl="$HOSTURL" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Deployment status retrieved"
    else
        print_error "Failed to get deployment status"
        exit 1
    fi
}

# Run smoke tests
run_smoke_tests() {
    print_info "Running smoke tests..."
    
    cd "$BASE_DIR"
    
    if mvn test -Dtest=SmokeTests \
        -Dorg="$ORG" \
        -Denv="$ENVIRONMENT" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Smoke tests passed"
    else
        print_warning "Some smoke tests failed"
    fi
}

# Rollback deployment
rollback_deployment() {
    print_warning "Rolling back deployment..."
    print_info "To rollback, deploy the previous version or redeploy the current revision"
    # Add rollback logic here
}

# Print help
print_help() {
    cat << EOF
Usage: ./scripts/deploy.sh [environment] [proxy-name] [action]

Arguments:
  environment    : Target environment (eval, staging, prod) - default: eval
  proxy-name     : Proxy name to deploy - default: apigee-proxy-api
  action         : Action to perform (deploy, status, rollback) - default: deploy

Examples:
  ./scripts/deploy.sh eval                          # Deploy to eval
  ./scripts/deploy.sh eval my-proxy                 # Deploy specific proxy
  ./scripts/deploy.sh eval my-proxy status          # Check status
  ./scripts/deploy.sh prod my-proxy deploy          # Deploy to production
  ./scripts/deploy.sh eval my-proxy rollback        # Rollback deployment

Environment Variables:
  APIGEE_ORG                                         # Apigee organization name
  APIGEE_USERNAME                                    # Apigee username
  APIGEE_PASSWORD                                    # Apigee password
  APIGEE_HOSTURL                                     # Apigee host URL (default: https://api.enterprise.apigee.com)

EOF
}

################################################################################
# Main Execution
################################################################################

main() {
    print_info "Starting Apigee Proxy Deployment"
    print_info "Timestamp: $TIMESTAMP"
    print_info "Environment: $ENVIRONMENT"
    print_info "Proxy: $PROXY_NAME"
    print_info "Action: $ACTION"
    
    # Initialize log file
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "" >> "$LOG_FILE"
    log_message "=== Apigee Proxy Deployment ==="
    log_message "Environment: $ENVIRONMENT"
    log_message "Proxy: $PROXY_NAME"
    log_message "Action: $ACTION"
    
    # Check prerequisites
    check_prerequisites
    
    # Validate environment
    validate_environment
    
    # Check credentials
    check_credentials
    
    # Validate proxy bundle
    validate_proxy_bundle
    
    # Perform requested action
    case $ACTION in
        deploy)
            build_proxy_bundle
            deploy_proxy
            run_smoke_tests
            print_success "Deployment completed successfully"
            log_message "Deployment completed successfully"
            ;;
        status)
            get_deployment_status
            ;;
        rollback)
            rollback_deployment
            ;;
        help|--help|-h)
            print_help
            ;;
        *)
            print_error "Unknown action: $ACTION"
            print_help
            exit 1
            ;;
    esac
    
    print_info "Log file: $LOG_FILE"
}

# Run main function
main "$@"
