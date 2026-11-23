# Counsellor Portal - Student Admission Management System

A production-ready Spring Boot web application designed for academic counsellors and admission teams to track student enquiries, manage leads, schedule follow-ups, and monitor conversion metrics.

---

## 1. Tech Stack

- **Backend**: Spring Boot 3.5.4 (Java 17 / 21)
- **Persistence**: Spring Data JPA & Hibernate ORM
- **Database**: MySQL 8.0+ (with embedded H2 database support)
- **Frontend / Templating**: Thymeleaf Server-Side Rendering (SSR)
- **UI & Styling**: Bootstrap 5.3.3 & Bootstrap Icons
- **Build Tool**: Apache Maven (Wrapper included: `mvnw` / `mvnw.cmd`)

---

## 2. Prerequisites

Ensure the following are installed on your machine:

1. **Java JDK 17 or 21**:
   ```bash
   java -version
   ```
2. **Maven 3.9+** (optional; the repository includes `mvnw.cmd` and `./mvnw` wrappers).
3. **MySQL Server 8.0+** (or use the zero-setup embedded H2 database option below).

---

## 3. Database Configuration

Database configuration is managed in `src/main/resources/application.properties`.

By default, the application connects to a local MySQL instance:
- **JDBC URL**: `jdbc:mysql://localhost:3306/counsellor_db?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC`
- **Username**: `root`
- **Password**: `root`

### Optional Environment Variables:
You can override the database credentials by setting environment variables or passing parameters:

| Environment Variable | Default Value | Description |
|---|---|---|
| `PORT` | `8080` | Web server port |
| `DB_URL` | `jdbc:mysql://localhost:3306/counsellor_db...` | MySQL connection string |
| `DB_USERNAME` | `root` | Database username |
| `DB_PASSWORD` | `root` | Database password |

---

## 4. How to Run the Application

Navigate to the project root directory in your terminal:

```cmd
cd D:\OneDrive\Desktop\Counsellor_Portal_Mini_Project_1
```

### Method 1: Run with Maven Wrapper (Recommended for Development)

#### On Windows (Command Prompt / PowerShell):
```cmd
mvnw.cmd spring-boot:run
```

#### On Linux / macOS:
```bash
./mvnw spring-boot:run
```

---

### Method 2: Build and Run the Packaged JAR (Fastest)

1. **Package the application into an executable JAR**:
   ```cmd
   mvnw.cmd package -DskipTests
   ```
2. **Run the JAR**:
   ```cmd
   java -jar target/04-Counsellors-Portal-0.0.1-SNAPSHOT.jar
   ```

---

### Method 3: Instant Zero-Setup Run with Embedded H2 (No MySQL Needed)

If MySQL is not installed or currently stopped on your machine, you can run the application immediately using the built-in in-memory database:

```cmd
java -jar target/04-Counsellors-Portal-0.0.1-SNAPSHOT.jar --spring.datasource.url=jdbc:h2:mem:counsellordb;DB_CLOSE_DELAY=-1;MODE=MySQL --spring.datasource.driver-class-name=org.h2.Driver --spring.datasource.username=sa --spring.datasource.password=
```

---

## 5. Application Endpoints & URLs

Once the application starts, access it in your browser:

| Feature / Page | URL | Description |
|---|---|---|
| **Sign In** | [http://localhost:8080/](http://localhost:8080/) | Counsellor authentication |
| **Register** | [http://localhost:8080/register](http://localhost:8080/register) | Create a new counsellor account |
| **Dashboard** | [http://localhost:8080/dashboard](http://localhost:8080/dashboard) | Conversion rates, KPIs & follow-up queue |
| **Add Enquiry** | [http://localhost:8080/enquiry](http://localhost:8080/enquiry) | Register a prospective student lead |
| **View Enquiries** | [http://localhost:8080/view-enquiries](http://localhost:8080/view-enquiries) | Search, filter, view profile, edit, delete |
| **Health Check** | [http://localhost:8080/health](http://localhost:8080/health) | Probe for application & database status |

---

## 6. Key Application Features

- **Duplicate Prevention**: Prevents multiple accounts with the same email address.
- **Role-Based Ownership**: Counsellors only view, edit, and manage their assigned student enquiries.
- **Dynamic Enquiry Filtering**: Instant filtering by Training Mode (*Online* / *Classroom*), Course name, and Status (*OPEN*, *ENROLLED*, *LOST*).
- **Auto Data Seeding**: `DataInitializer` automatically populates essential training courses on first run if the database is empty:
  - Java Full Stack
  - Python Full Stack
  - DevOps & Cloud (AWS)
  - Data Science & AI
  - Full Stack Web Development
- **Live Search**: Client-side instant keyword search across student names and phone numbers.
- **Admission Pipeline Visualizer**: Step-by-step progress tracker for student counseling stages.
- **Audit Timestamps**: Automatic non-destructive timestamp management (`createdAt`, `updatedAt`).

---

## 7. Running Tests

To run the automated test suite:

```cmd
mvnw.cmd test
```
All unit and integration tests run against an isolated in-memory test database independently of external services.
