<p align="center">
  <img src="https://spring-petclinic.github.io/images/spring-petclinic.png" alt="Spring Petclinic" width="200">
</p>

<h1 align="center">Harness Petclinic</h1>

<p align="center">
  <strong>AI-Powered CI/CD with Multi-Stage Java Builds</strong><br>
  Spring Petclinic deployed via Harness CI/CD with Gemma 4 AI security gate, multi-stage Docker builds, and canary deployments to Kubernetes.
</p>

---

## What This Is

The classic [Spring Petclinic](https://github.com/spring-projects/spring-petclinic) application, wired up with a full Harness CI/CD pipeline featuring an AI-powered code review gate using Google Gemma 4 running on-prem via Ollama. Built as a companion to [harness-demo](https://github.com/scarolan/harness-demo) to show Harness working with a Java/Spring Boot stack.

**Why Petclinic?** It's the canonical Spring Boot demo app — every Java developer recognizes it. It has real controllers, JPA entities, Thymeleaf templates, and test coverage. It's not a toy.

## Architecture

```
Developer pushes code
  --> GitHub webhook
  --> Harness CI/CD Pipeline
        |
        +--> AI Code Review (Gemma 4 26B via Ollama - on-prem)
        |      Reviews Java source for OWASP Top 10 vulnerabilities
        |      CRITICAL security issues --> pipeline BLOCKED
        |
        +--> Security Gate
        |      Reads AI verdict, enforces pass/fail
        |
        +--> Maven Tests (./mvnw test)
        |
        +--> Multi-Stage Docker Build (JDK builder -> JRE runtime)
        |
        +--> Canary Deploy (1 pod)
        +--> Canary Delete
        +--> Rolling Deploy (full rollout)
  --> App live on Kubernetes
```

## Components

| Component | Technology | Where it runs |
|-----------|-----------|---------------|
| Application | Spring Boot 4.1 / Java 17 | Kubernetes pod |
| CI/CD Pipeline | Harness | SaaS control plane |
| Build Infrastructure | Harness Delegate | Kubernetes (self-managed) |
| AI Code Review | Gemma 4 26B QAT | On-prem via Ollama |
| Container Build | Kaniko (multi-stage) | Kubernetes pod |
| Container Registry | DockerHub | Cloud |
| Source Control | GitHub | Cloud |
| Deployment Strategy | Canary + Rolling | Kubernetes |

## Features

- **AI Security Gate**: Gemma 4 reviews every PR for OWASP Top 10 vulnerabilities — SQL/HQL injection, unsafe deserialization, mass assignment, hardcoded secrets. All caught and blocked.
- **Multi-Stage Docker Build**: JDK 17 builder stage compiles the JAR, JRE 17 runtime stage runs it. This is where multi-stage builds actually matter — the final image drops the full JDK, Maven, and all build tools.
- **Canary Deployments**: New versions deploy to a single canary pod first, then roll out to full replicas with automatic rollback on failure.
- **Spring Boot Health Probes**: Kubernetes liveness and readiness probes wired to Spring Actuator endpoints (`/actuator/health/liveness`, `/actuator/health/readiness`).
- **Git Triggers**: Pipeline runs automatically on push to main and on PR open/update.
- **OPA Governance**: Policy enforces that every pipeline must include an AI Code Review step — can't save a pipeline without it.

## Why Multi-Stage Works Here (and Not in the Python Demo)

The [Python harness-demo](https://github.com/scarolan/harness-demo) uses a single-stage Dockerfile because Python is interpreted — the runtime needs the same packages the build uses. A multi-stage build only saves pip cache (~20MB).

Java is different. The build needs:
- Full JDK (compiler, build tools): ~400MB
- Maven + dependency cache: ~300MB

The runtime only needs:
- JRE: ~200MB
- The compiled JAR: ~50MB

Multi-stage cuts the image from ~750MB to ~250MB. That's a real win.

## Running the Demo

### Prerequisites

- Docker Desktop with Kubernetes enabled
- Ollama running with `gemma4:26b-a4b-it-qat` model
- Harness account with delegate installed
- GitHub and DockerHub accounts
- Java 17+ (for local development)

### Demo Scripts

```bash
# Inject a JPA injection vulnerability, open a PR — watch Gemma block it
./scripts/demo-start.sh

# Fix the vulnerability, push — watch Gemma approve it
./scripts/demo-fix.sh

# Clean up for next demo run
./scripts/demo-reset.sh
```

### Local Development

```bash
./mvnw spring-boot:run
# App runs on http://localhost:8080
```

### Running Tests

```bash
./mvnw test
```

## Project Structure (Harness additions)

```
harness-petclinic/
  src/                           # Spring Petclinic source (unchanged)
  scripts/
    ai_review.py                 # Gemma 4 AI code review (JSON mode)
    demo-start.sh                # Inject JPA injection for demo
    demo-fix.sh                  # Fix vulnerability for demo
    demo-reset.sh                # Reset demo state
  k8s-harness/
    namespace.yaml               # Dedicated namespace
    deployment.yaml              # K8s deployment with actuator probes
    service.yaml                 # NodePort service on 30081
  Dockerfile                     # Multi-stage: JDK builder -> JRE runtime
  pom.xml                        # Maven build (from upstream)
```

## Demo Vulnerability: JPA Injection

The demo injects a classic JPA/HQL injection into the `OwnerController`:

```java
// VULNERABLE — string concatenation in JPQL query
em.createQuery("SELECT o FROM Owner o WHERE o.lastName LIKE '%" + query + "%'", Owner.class)
```

The fix uses Spring Data's built-in repository method:

```java
// SAFE — parameterized via Spring Data
this.owners.findByLastName(query);
```

The AI reviewer catches this as **CRITICAL: SQL/HQL Injection (A03:2021)** and blocks the pipeline.

## Comparison with Python Demo

| Aspect | harness-demo (Python) | harness-petclinic (Java) |
|--------|----------------------|--------------------------|
| Framework | FastAPI | Spring Boot 4.1 |
| Language | Python 3.12 | Java 17 |
| Docker Build | Single-stage (slim) | Multi-stage (JDK -> JRE) |
| Image Size | ~140MB | ~250MB (down from ~750MB) |
| AI Review Time | ~20s | ~30-45s (more source files) |
| Test Framework | pytest | JUnit 5 / Spring Test |
| Health Checks | Custom `/health` endpoint | Spring Actuator |
| Demo Vulnerability | SQL injection (sqlite3) | JPA injection (EntityManager) |
| K8s Port | 30080 | 30081 |

Both demos show the same Harness capabilities — AI security gate, canary deployments, pipeline templates, OPA governance — just with different tech stacks. Together they demonstrate that the platform is language-agnostic.

---

<p align="center">
  Built with Claude Code, Harness CI/CD, and Gemma 4 via Ollama<br>
  <em>No code left the network.</em>
</p>
