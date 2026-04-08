# =============================================================================
# WSO2 API Manager — Custom Docker Image
# =============================================================================
ARG WSO2_VERSION=4.3.0

FROM wso2/wso2am:${WSO2_VERSION}

LABEL maintainer="wso2@ticxar.com"
LABEL description="WSO2 API Manager custom image"

ARG ENVIRONMENT=dev

# Copiar artefactos custom
COPY projects/api-manager/policies/ ${WSO2_SERVER_HOME}/repository/deployment/server/synapse-configs/default/sequences/

# Copiar configuración por ambiente
COPY config/${ENVIRONMENT}/apim/ ${WSO2_SERVER_HOME}/repository/conf/

# Exponer puertos
# 9443 - Management Console (HTTPS)
# 8243 - Gateway (HTTPS)
# 8280 - Gateway (HTTP)
EXPOSE 9443 8243 8280

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=5 --start-period=120s \
    CMD curl -sSk https://localhost:9443/services/Version || exit 1
