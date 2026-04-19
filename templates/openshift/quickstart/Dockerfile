# ============================================================
# Multi-stage Dockerfile para aplicación Java en OpenShift
# Compatible con OCP 4.12+ y Podman/Docker
# ============================================================

# --- Stage 1: Build ---
FROM registry.access.redhat.com/ubi8/openjdk-17:latest AS builder

USER root
WORKDIR /build

# Copiar archivos de dependencias primero (cache de capas)
COPY pom.xml ./
RUN mvn dependency:go-offline -B

# Copiar código fuente y compilar
COPY src/ ./src/
RUN mvn package -DskipTests -B && \
    mv target/*.jar target/app.jar

# --- Stage 2: Runtime ---
FROM registry.access.redhat.com/ubi8/openjdk-17-runtime:latest

LABEL io.openshift.tags="java,quickstart" \
      io.openshift.expose-services="8080:http" \
      io.k8s.description="Aplicación Java para OCP Quickstart" \
      io.k8s.display-name="OCP Quickstart App" \
      maintainer="TICXAR <devops@ticxar.com>"

# OpenShift ejecuta contenedores con UID arbitrario en el grupo root
USER 1001

WORKDIR /deployments

COPY --from=builder --chown=1001:0 /build/target/app.jar ./app.jar

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0" \
    AB_JOLOKIA_OFF="true"

EXPOSE 8080

ENTRYPOINT ["java"]
CMD ["-jar", "app.jar"]
