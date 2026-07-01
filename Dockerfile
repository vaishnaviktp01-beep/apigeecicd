# Multi-stage build for Apigee Proxy

# Stage 1: Build stage
FROM maven:3.8.6-openjdk-11-slim as builder

WORKDIR /app

# Copy pom.xml
COPY pom.xml .

# Copy source code
COPY src ./src

# Build the project
RUN mvn clean package -DskipTests

# Stage 2: Runtime stage
FROM maven:3.8.6-openjdk-11-slim

WORKDIR /app

# Copy built artifacts from builder
COPY --from=builder /app/target ./target
COPY --from=builder /app/pom.xml .
COPY --from=builder /app/src ./src

# Install additional tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Copy scripts
COPY scripts/ ./scripts/
RUN chmod +x ./scripts/*.sh

# Copy configuration
COPY config/ ./config/

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Set environment variables
ENV MAVEN_OPTS="-Xmx512m -XX:MaxPermSize=256m"
ENV JAVA_OPTS="-Xms256m -Xmx512m"

# Entry point
ENTRYPOINT ["sh", "-c", "mvn --version && echo 'Docker container ready for Apigee proxy deployment'"]

# Labels
LABEL maintainer="DevOps Team" \
      description="Docker image for Apigee proxy deployment" \
      version="1.0.0"
