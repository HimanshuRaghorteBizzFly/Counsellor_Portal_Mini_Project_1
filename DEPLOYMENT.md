# Production Deployment & Containerization Guide: Counsellor Portal

This guide provides end-to-end instructions for containerizing, developing, testing, and deploying the **Counsellor Portal** application locally with Docker Compose, on standard cloud container platforms (Render, Railway, AWS ECS, GCP Cloud Run), and on **Vercel**.

---

## 1. Project Architecture

The **Counsellor Portal** is a production-grade, monolithic Java web application:
- **Backend Framework**: Spring Boot 3.5.4 (Jakarta EE 10, Spring Web, Spring Data JPA, Hibernate ORM 6.6).
- **Frontend / UI**: Thymeleaf Server-Side Rendering (SSR) integrated with Bootstrap 5.3.3 and Bootstrap Icons via CDN, plus custom CSS (`/css/style.css`) and responsive client-side DOM filtering.
- **Java Runtime**: OpenJDK 17 (Eclipse Temurin 17-jre-alpine for minimal container footprint).
- **Database**: MySQL 8.0+ connected via `com.mysql.cj.jdbc.Driver` using resilient HikariCP connection pooling (`spring.datasource.hikari`).
- **Session & Auth**: Stateful HTTP Session (`HttpSession`) with cookie security (`HttpOnly`, `SameSite=Lax`).
- **Observability / Health**: Dedicated health check endpoints at `/health` and `/api/health` validating both application and database connectivity.
- **Data Seeding**: Automated `DataInitializer` and idempotent `init.sql` ensuring prerequisite course lists exist on first boot.

```
                           +-------------------------------------+
                           |            End User Client          |
                           +-------------------------------------+
                                              |
                     HTTPS / TLS (Port 443)   |
                                              v
                 +-------------------------------------------------+
                 |  Vercel Edge Network (Edge CDN / Reverse Proxy) |
                 |           Configured via vercel.json            |
                 +-------------------------------------------------+
                                              |
                   Upstream Proxy / Rewrites  |
                                              v
                 +-------------------------------------------------+
                 |    Spring Boot Container (Port 8080)            |
                 |    (Docker / Railway / Render / AWS ECS)        |
                 |  - Embedded Tomcat                              |
                 |  - Thymeleaf View Resolver                      |
                 |  - Controllers: Counsellor, Enquiry, Health     |
                 |  - Non-root user: appuser (Alpine Linux)        |
                 +-------------------------------------------------+
                                              |
                             TCP / JDBC:3306  |
                                              v
                 +-------------------------------------------------+
                 |     MySQL 8.0 Database (Persistent Storage)     |
                 |     (Local Named Volume / Cloud Managed DB)     |
                 +-------------------------------------------------+
```

---

## 2. Docker Installation & Prerequisites

To build and run this project, ensure you have:
1. **Docker Desktop** (version 24.0+ or 29.0+) with Docker Compose v2+.
2. **Java JDK 17 or 21** (if building or running tests locally without Docker).
3. **Maven 3.9+** (included via `./mvnw` and `mvnw.cmd` wrapper scripts in the repository).
4. **Git** (version 2.30+).

Verify your environment:
```bash
docker --version
docker compose version
java -version
```

---

## 3. Environment Variables Setup

Configuration is decoupled from application code and injected strictly via environment variables.

### Template File
A complete `.env.example` file is provided in the repository root. Duplicate it to create your local `.env`:

```bash
cp .env.example .env
```

> [!CAUTION]
> Never commit `.env` or files containing database passwords into Git. `.gitignore` and `.dockerignore` are configured to prevent secrets from leaking.

### Environment Variables Reference

| Variable Name | Default Value | Description |
|---|---|---|
| `PORT` | `8080` | Port on which the Spring Boot web server binds. |
| `SPRING_PROFILES_ACTIVE` | `dev` / `prod` | Spring profile controlling logging and behavior. |
| `DB_URL` | `jdbc:mysql://db:3306/counsellor_db?...` | Complete JDBC database connection string. |
| `DB_USERNAME` | `counsellor_user` | MySQL database username. |
| `DB_PASSWORD` | `counsellor_password` | MySQL database password. |
| `DB_POOL_MAX_SIZE` | `10` | Maximum HikariCP connection pool connections. |
| `DB_POOL_MIN_IDLE` | `2` | Minimum HikariCP idle pool connections. |
| `DB_TIMEOUT` | `30000` | HikariCP connection timeout in milliseconds. |
| `CORS_ALLOWED_ORIGINS` | `*` (or comma-separated URLs) | Allowed origins for cross-origin requests. |
| `MYSQL_ROOT_PASSWORD` | `root_secure_password` | Root password used by local Docker Compose MySQL. |
| `MYSQL_DATABASE` | `counsellor_db` | Database name initialized in local MySQL container. |
| `MYSQL_USER` | `counsellor_user` | Application user created in local MySQL container. |
| `MYSQL_PASSWORD` | `counsellor_password` | Application user password in local MySQL container. |
| `MYSQL_LOCAL_PORT` | `3306` | Local host port bound to MySQL (bound to `127.0.0.1`). |
| `BACKEND_URL` | `http://localhost:8080` | Upstream backend URL for Vercel edge reverse proxy. |

---

## 4. Local Development with Docker Compose

Docker Compose coordinates both the Spring Boot application and the MySQL 8 database service with full healthcheck orchestration and persistent storage.

### 4.1 Start the Stack
```bash
docker compose up -d
```

### 4.2 Inspect Container Status
```bash
docker compose ps
```
Output:
```
NAME             IMAGE                          STATUS                   PORTS
counsellor-app   counsellor-portal-app:latest   Up (healthy)             0.0.0.0:8080->8080/tcp
counsellor-db    mysql:8.0-debian               Up (healthy)             127.0.0.1:3306->3306/tcp
```

### 4.3 View Real-Time Logs
```bash
# View application logs
docker compose logs -f app

# View database logs
docker compose logs -f db
```

### 4.4 Test the Running Application
Open your browser or run:
```bash
# Health check
curl http://localhost:8080/health

# Web application landing page
curl http://localhost:8080/
```
In your browser, visit: `http://localhost:8080/`

### 4.5 Stop the Stack
```bash
# Stop containers (preserves database data volume)
docker compose down

# Stop containers and remove volumes (CAUTION: wipes database)
docker compose down -v
```

---

## 5. Single Container Build & Run

If you want to build and test the standalone application container image:

### 5.1 Build the Production Image
```bash
docker build -t counsellor-portal-app:latest .
```
- **Base image**: `maven:3.9.9-eclipse-temurin-17-alpine` (Build stage) & `eclipse-temurin:17-jre-alpine` (Runtime stage).
- **Security**: Runs under non-root user `appuser:appgroup`.
- **Image Size**: ~121 MB (compact, minimal attack surface).

### 5.2 Run Container Against an External Database
```bash
docker run -d \
  --name counsellor-app \
  -p 8080:8080 \
  -e PORT=8080 \
  -e DB_URL="jdbc:mysql://<host>:3306/counsellor_db?createDatabaseIfNotExist=true&useSSL=true&allowPublicKeyRetrieval=true" \
  -e DB_USERNAME="your_user" \
  -e DB_PASSWORD="your_password" \
  counsellor-portal-app:latest
```

---

## 6. Vercel Deployment Architecture & Instructions

### 6.1 Architectural Analysis: Vercel vs Spring Boot

| Capability | Vercel Standard / Serverless | Spring Boot Application Requirement | Compatibility Assessment |
|---|---|---|---|
| **Runtime Model** | Ephemeral Serverless Functions (Node.js, Go, Python, Ruby) | Persistent Java Virtual Machine (JVM) daemon | **Incompatible** on standard Serverless Functions without container runtime. |
| **Startup / Cold-Start** | 50ms - 500ms expected | 3s - 8s (JVM class loading & Spring Context) | JVM cold starts cause severe request latency on serverless invocations. |
| **Session State** | Stateless (separate invocation instances) | In-memory `HttpSession` (`session.setAttribute("CID", ...)`) | **Requires sticky sessions** or external Redis session store (`spring-session`). |
| **Database** | Ephemeral, no built-in relational database | Requires long-lived TCP connection pool to MySQL | Vercel does not host MySQL; external DB required (Railway, PlanetScale, Aiven). |
| **Container Runtime** | Experimental / Enterprise beta (`Dockerfile.vercel`) | Fully supported via standard OCI Docker container | Usable if Vercel Container Runtime is activated on your Vercel plan. |

### 6.2 Recommended Cloud Architecture: Hybrid Deployment
Because the Counselor Portal is a server-rendered Spring Boot monolithic application with stateful sessions:
1. **Backend & Database**: Deploy the Docker container on **Railway**, **Render**, **Fly.io**, or **AWS ECS/App Runner**, connected to a managed MySQL database.
2. **Edge Network & Domain**: Deploy `vercel.json` to **Vercel**. Vercel acts as the global Edge CDN:
   - Caches static CSS and assets at edge locations worldwide (`/css/*` cached for 1 year).
   - Enforces strict security headers (`X-Frame-Options`, `X-Content-Type-Options`, `X-XSS-Protection`).
   - Seamlessly proxies and rewrites dynamic web requests to your backend deployment URL.

### 6.3 Deploying to Vercel (Step-by-Step)

#### Step 1: Deploy Backend Container
First deploy the containerized backend to Railway, Render, or Fly.io (see Section 7) to obtain a live backend URL (e.g., `https://counsellor-backend.up.railway.app`).

#### Step 2: Configure `vercel.json`
Update the `destination` URL in `vercel.json`:
```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "version": 2,
  "cleanUrls": true,
  "headers": [
    {
      "source": "/css/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        }
      ]
    }
  ],
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "https://<your-backend-service-url>/$1"
    }
  ]
}
```

#### Step 3: Deploy via Vercel CLI or Dashboard
```bash
# Using Vercel CLI
npx vercel --prod
```
Or connect your GitHub repository directly in the [Vercel Dashboard](https://vercel.com/new).

### 6.4 Using `Dockerfile.vercel` (Vercel Container Runtime)
If your Vercel organization is enrolled in the Vercel Container Runtime preview:
- Vercel automatically detects `Dockerfile.vercel`.
- Set environment variables in the Vercel Project Settings:
  - `PORT`: `8080` (or leave default for Vercel port forwarding).
  - `DB_URL`: `jdbc:mysql://<host>:<port>/counsellor_db?createDatabaseIfNotExist=true&useSSL=true&allowPublicKeyRetrieval=true`
  - `DB_USERNAME`: `<username>`
  - `DB_PASSWORD`: `<password>`
  - `SPRING_PROFILES_ACTIVE`: `prod`

---

## 7. Backend Container Deployment (Render & Railway)

### 7.1 Deploying to Railway (Zero-Config Dockerfile)
1. Log in to [Railway.app](https://railway.app/).
2. Click **New Project** &rarr; **Provision MySQL**.
3. Once MySQL is provisioned, click **New Service** &rarr; **GitHub Repo** &rarr; select `Counsellor_Portal`.
4. Railway detects `Dockerfile` automatically.
5. In **Variables**, add:
   - `PORT`: `8080`
   - `DB_URL`: `jdbc:mysql://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true`
   - `DB_USERNAME`: `${{MySQL.MYSQLUSER}}`
   - `DB_PASSWORD`: `${{MySQL.MYSQLPASSWORD}}`
   - `SPRING_PROFILES_ACTIVE`: `prod`
6. Click **Deploy**. Railway builds the multi-stage Docker image and deploys with health check monitoring.

### 7.2 Deploying to Render
1. Log in to [Render.com](https://render.com/).
2. Create a **MySQL / PostgreSQL** database (or use an external MySQL like Aiven / PlanetScale).
3. Click **New Web Service** &rarr; connect repository.
4. Set **Environment** to `Docker` (Render automatically uses `Dockerfile`).
5. In **Environment Variables**, provide `PORT`, `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`.
6. Set **Health Check Path** to `/health`.
7. Click **Create Web Service**.

---

## 8. Database Architecture & Persistence

- **Preservation of Existing Architecture**: The existing JPA entities (`Counsellor`, `Enquiry`, `Course`) and relationships are completely preserved.
- **Auto-DDL Configuration**: `spring.jpa.hibernate.ddl-auto=update` is configured in `application.properties`, ensuring schema updates occur non-destructively.
- **Data Persistence**:
  - In Docker Compose, the `mysql_data` named volume persists all data across container restarts and updates.
  - In Cloud deployments, managed databases provide persistent SSD block storage with automated daily backups.
- **File Uploads & User Content**: Currently, the application processes text-based student lead records. If file uploads (e.g., student resumes, ID verification) are introduced, store them in cloud object storage (AWS S3, Cloudflare R2, Google Cloud Storage) and save only the object URL in MySQL. Never store permanent user assets inside the ephemeral container filesystem.

---

## 9. Security Audit & Hardening Checklist

The following security controls have been implemented:

- [x] **Zero Hardcoded Secrets**: All database URLs, credentials, and ports are externalized via environment variables.
- [x] **Safe Local Fallbacks**: Resilient defaults prevent local startup crashes while production environments enforce secure variables.
- [x] **Secure Session Cookies**: `server.servlet.session.cookie.http-only=true` and `server.servlet.session.cookie.same-site=lax` prevent XSS session hijacking.
- [x] **Non-Root Container User**: Container runs as unprivileged user `appuser:appgroup` (UID 1000) inside Alpine Linux.
- [x] **Internal Database Isolation**: In `docker-compose.yml`, MySQL port 3306 is bound strictly to `127.0.0.1` and isolated on `counsellor-network` to prevent external internet exposure.
- [x] **Protected Version Control**: `.gitignore` and `.dockerignore` prevent `.env`, `.env.*`, keys, and temporary artifacts from being committed or built into Docker layers.
- [x] **Production Dependency Isolation**: Test dependencies (`com.h2database:h2`, `spring-boot-starter-test`) are scoped to `<scope>test</scope>` and omitted from the production jar.
- [x] **CORS Origin Filtering**: Dynamic origin matching prevents unauthorized cross-origin API abuse.

---

## 10. Troubleshooting Guide

### Issue 1: Database Connection Refused (`CommunicationsException`)
- **Symptoms**: `java.net.ConnectException: Connection refused: /db:3306`
- **Cause**: Application container started before MySQL finished initializing.
- **Solution**: Docker Compose uses `condition: service_healthy` on MySQL's `mysqladmin ping`. If running manually, ensure MySQL is healthy before starting the app.

### Issue 2: Dialect Metadata Failure on Clean Build
- **Symptoms**: `HibernateException: Unable to determine Dialect without JDBC metadata`
- **Cause**: Building or testing without a running MySQL instance.
- **Solution**: Resolved. The test suite now includes an H2 in-memory test configuration in `src/test/resources/application.properties` that executes unit tests independently of MySQL.

### Issue 3: Port 8080 or 3306 Already in Use
- **Symptoms**: `Bind for 0.0.0.0:8080 failed: port is already allocated`
- **Solution**: Pass an alternative port in your `.env` or run:
  ```bash
  PORT=8081 MYSQL_LOCAL_PORT=3307 docker compose up -d
  ```

### Issue 4: Session Lost / Logged Out Immediately on Vercel
- **Symptoms**: Logging in redirects back to `/` instead of staying on `/dashboard`.
- **Cause**: Serverless environments do not maintain in-memory sessions across ephemeral invocations.
- **Solution**: Use the recommended Hybrid Architecture (Section 6.2) where the backend runs as a continuous container daemon, or configure Spring Session with Redis (`spring-session-data-redis`).

---

## 11. Free-Plan Limitations and Expected Costs

| Platform | Free Tier Feasibility | Limitations & Constraints | Estimated Monthly Cost |
|---|---|---|---|
| **Local Docker** | 100% Free | Requires Docker Desktop installed on host. | $0.00 |
| **Vercel** | Free (Hobby Plan) | Serverless functions only (no native background JVM daemons). Best used as Edge CDN / reverse proxy via `vercel.json`. | $0.00 (Hobby) |
| **Railway** | $5 Free Credit (Trial) | Containers sleep after trial; requires paid plan for 24/7 production ($5/mo baseline). | ~$5 - $10 / month |
| **Render** | Free Tier Available | Free Web Services spin down after 15 minutes of inactivity; 50-second cold start on first request. | $0.00 (Free) or $7/mo |
| **Managed MySQL (Aiven / PlanetScale)** | Free / Trial tiers | Limited storage (5 GB) and connection limits. | $0.00 - $15 / month |

---

## 12. Local Quick-Start Cheat Sheet

```bash
# 1. Clone repository
git clone <repo-url>
cd Counsellor_Portal

# 2. Configure environment
cp .env.example .env

# 3. Build & start local Docker stack
docker compose up -d

# 4. Verify health
curl http://localhost:8080/health

# 5. Access UI in browser
# Open: http://localhost:8080/

# 6. Stop stack when finished
docker compose down
```
