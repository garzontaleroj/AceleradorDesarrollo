@smoke @health
Feature: API Health Check — WSO2 APIs
  Verificar que las APIs estén disponibles y respondiendo correctamente.

  Background:
    * url baseUrl
    * header Authorization = accessToken

  # ---------------------------------------------------------------------------
  # Verificación de salud del Gateway APIM
  # ---------------------------------------------------------------------------
  Scenario: APIM Gateway responde correctamente
    Given url apimGatewayUrl
    And path '/services/Version'
    When method GET
    Then status 200

  # ---------------------------------------------------------------------------
  # Verificación de salud del Micro Integrator
  # ---------------------------------------------------------------------------
  Scenario: MI Health Check
    Given url miHttpUrl
    And path '/healthz'
    When method GET
    Then status 200

  # ---------------------------------------------------------------------------
  # Verificación de la API principal
  # ---------------------------------------------------------------------------
  Scenario: API responde con 200 OK
    Given path '/'
    When method GET
    Then status 200
    And match response != null
    And match responseHeaders['Content-Type'][0] contains 'application/json'

  # ---------------------------------------------------------------------------
  # Verificación con token inválido (debe rechazar)
  # ---------------------------------------------------------------------------
  @security
  Scenario: API rechaza token inválido
    Given path '/'
    And header Authorization = 'Bearer token_invalido_12345'
    When method GET
    Then status 401
    And match response.fault.message contains 'Invalid Credentials'
