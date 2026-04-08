# =============================================================================
# WSO2 Micro Integrator — Custom Docker Image
# =============================================================================
ARG MI_VERSION=4.3.0

FROM wso2/wso2mi:${MI_VERSION}

LABEL maintainer="wso2@ticxar.com"
LABEL description="WSO2 Micro Integrator custom image"

ARG ENVIRONMENT=dev

# Copiar artefactos Synapse
COPY projects/micro-integrator/src/main/synapse-config/api/ \
     ${WSO2_SERVER_HOME}/repository/deployment/server/synapse-configs/default/api/

COPY projects/micro-integrator/src/main/synapse-config/endpoints/ \
     ${WSO2_SERVER_HOME}/repository/deployment/server/synapse-configs/default/endpoints/

COPY projects/micro-integrator/src/main/synapse-config/proxy-services/ \
     ${WSO2_SERVER_HOME}/repository/deployment/server/synapse-configs/default/proxy-services/

COPY projects/micro-integrator/src/main/synapse-config/sequences/ \
     ${WSO2_SERVER_HOME}/repository/deployment/server/synapse-configs/default/sequences/

# Copiar deployment.toml por ambiente
COPY config/${ENVIRONMENT}/mi/deployment.toml ${WSO2_SERVER_HOME}/conf/deployment.toml

# Copiar registry resources
COPY projects/micro-integrator/src/main/registry-resources/ \
     ${WSO2_SERVER_HOME}/registry/

# Exponer puertos
# 8290 - HTTP
# 8253 - HTTPS
# 9164 - Management API
EXPOSE 8290 8253 9164

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=5 --start-period=90s \
    CMD curl -sSk https://localhost:9164/management/apis || exit 1
