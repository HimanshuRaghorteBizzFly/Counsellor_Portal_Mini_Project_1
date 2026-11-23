# ===================================================================
# Stage 1: Build Spring Boot Application with Maven
# Multi-stage caching: separate dependency resolution from source build
# ===================================================================
FROM maven:3.9.9-eclipse-temurin-17-alpine AS build

WORKDIR /app

# Cache Maven dependencies
COPY pom.xml .
RUN mvn dependency:resolve -B

# Copy source code and build production jar
COPY src ./src
RUN mvn clean package -DskipTests -B

# ===================================================================
# Stage 2: Production Runtime with Minimal Eclipse Temurin Alpine JRE
# ===================================================================
FROM eclipse-temurin:17-jre-alpine

# Install curl for reliable container healthchecks
RUN apk add --no-cache curl

# Create non-root user and group for container security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy artifact from build stage
COPY --from=build --chown=appuser:appgroup /app/target/*.jar app.jar

# Switch to non-root user
USER appuser:appgroup

# Environment defaults
ENV PORT=8080 \
    SPRING_PROFILES_ACTIVE=prod \
    JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

# Document exposed application port
EXPOSE 8080

# Production Health Check
HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
  CMD curl -f http://localhost:${PORT:-8080}/health || exit 1

# Graceful startup entrypoint
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dserver.port=${PORT:-8080} -jar app.jar"]
