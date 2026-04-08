# =============================================================================
# WSO2 Streaming Integrator — Custom Docker Image
# =============================================================================
ARG SI_VERSION=4.2.0

FROM wso2/wso2si:${SI_VERSION}

LABEL maintainer="wso2@ticxar.com"
LABEL description="WSO2 Streaming Integrator custom image"

ARG ENVIRONMENT=dev

# Copiar Siddhi Apps
COPY projects/streaming-integrator/siddhi-apps/ \
     ${WSO2_SERVER_HOME}/deployment/siddhi-files/

# Copiar conectores custom
COPY projects/streaming-integrator/connectors/ \
     ${WSO2_SERVER_HOME}/lib/

# Copiar configuración por ambiente
COPY config/${ENVIRONMENT}/si/ ${WSO2_SERVER_HOME}/conf/server/

# Exponer puertos
# 9443 - Management Console (HTTPS)
# 9090 - HTTP
# 7611 - Thrift
# 7711 - Thrift SSL
EXPOSE 9443 9090 7611 7711

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=5 --start-period=90s \
    CMD curl -sSk https://localhost:9443/health || exit 1
