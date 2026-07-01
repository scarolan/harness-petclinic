FROM eclipse-temurin:17-jdk-jammy AS builder

ARG APP_VERSION=4.0.0
ARG COMMIT_SHA=unknown
ARG BUILD_TIME=unknown

WORKDIR /build

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -q

COPY src src
RUN ./mvnw package -DskipTests -q \
    && mv target/spring-petclinic-*.jar app.jar

FROM eclipse-temurin:17-jre-jammy

ARG APP_VERSION=4.0.0
ARG COMMIT_SHA=unknown
ARG BUILD_TIME=unknown

ENV APP_VERSION=${APP_VERSION} \
    COMMIT_SHA=${COMMIT_SHA} \
    BUILD_TIME=${BUILD_TIME} \
    SPRING_PROFILES_ACTIVE=default

WORKDIR /app

COPY --from=builder /build/app.jar app.jar

RUN useradd --create-home --shell /bin/bash appuser
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

CMD ["java", "-jar", "app.jar"]
