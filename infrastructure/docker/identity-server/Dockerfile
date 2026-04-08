# =============================================================================
# WSO2 Identity Server — Custom Docker Image
# =============================================================================
ARG IS_VERSION=7.0.0

FROM wso2/wso2is:${IS_VERSION}

LABEL maintainer="wso2@ticxar.com"
LABEL description="WSO2 Identity Server custom image"

ARG ENVIRONMENT=dev

# Copiar configuración por ambiente
COPY config/${ENVIRONMENT}/is/ ${WSO2_SERVER_HOME}/repository/conf/

# Exponer puertos
# 9443 - Management Console (HTTPS)
# 9763 - Management Console (HTTP)
EXPOSE 9443 9763

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=5 --start-period=120s \
    CMD curl -sSk https://localhost:9443/carbon/admin/login.jsp || exit 1
