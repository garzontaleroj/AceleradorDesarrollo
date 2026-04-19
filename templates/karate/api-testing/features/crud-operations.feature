@crud @functional
Feature: CRUD Operations — API REST WSO2
  Pruebas completas de operaciones CRUD para una API REST
  publicada en WSO2 API Manager / Micro Integrator.

  Background:
    * url baseUrl
    * header Authorization = accessToken

  # ---------------------------------------------------------------------------
  # CREATE — Crear un recurso
  # ---------------------------------------------------------------------------
  @create
  Scenario: Crear un nuevo recurso
    Given path '/'
    And request
      """
      {
        "name": "Recurso de prueba",
        "description": "Creado por Karate test",
        "active": true
      }
      """
    When method POST
    Then status 201
    And match response.id == '#notnull'
    And match response.name == 'Recurso de prueba'
    And match response.active == true
    # Guardar el ID para operaciones posteriores
    * def resourceId = response.id

  # ---------------------------------------------------------------------------
  # READ — Obtener todos los recursos
  # ---------------------------------------------------------------------------
  @read
  Scenario: Listar recursos
    Given path '/'
    When method GET
    Then status 200
    And match response == '#array'
    And match each response contains { id: '#notnull', name: '#string' }

  # ---------------------------------------------------------------------------
  # READ — Obtener un recurso por ID
  # ---------------------------------------------------------------------------
  @read
  Scenario: Obtener recurso por ID
    # Primero crear un recurso
    Given path '/'
    And request { "name": "Recurso temporal", "active": true }
    When method POST
    Then status 201
    * def resourceId = response.id

    # Luego obtenerlo por ID
    Given path '/', resourceId
    When method GET
    Then status 200
    And match response.id == resourceId
    And match response.name == 'Recurso temporal'

  # ---------------------------------------------------------------------------
  # UPDATE — Actualizar un recurso
  # ---------------------------------------------------------------------------
  @update
  Scenario: Actualizar un recurso existente
    # Crear recurso
    Given path '/'
    And request { "name": "Recurso original", "active": true }
    When method POST
    Then status 201
    * def resourceId = response.id

    # Actualizar
    Given path '/', resourceId
    And request
      """
      {
        "name": "Recurso actualizado",
        "description": "Modificado por Karate test",
        "active": false
      }
      """
    When method PUT
    Then status 200
    And match response.name == 'Recurso actualizado'
    And match response.active == false

  # ---------------------------------------------------------------------------
  # DELETE — Eliminar un recurso
  # ---------------------------------------------------------------------------
  @delete
  Scenario: Eliminar un recurso
    # Crear recurso
    Given path '/'
    And request { "name": "Recurso a eliminar", "active": true }
    When method POST
    Then status 201
    * def resourceId = response.id

    # Eliminar
    Given path '/', resourceId
    When method DELETE
    Then status 204

    # Verificar que ya no existe
    Given path '/', resourceId
    When method GET
    Then status 404

  # ---------------------------------------------------------------------------
  # Validaciones de entrada
  # ---------------------------------------------------------------------------
  @validation
  Scenario: Rechazar request sin campos requeridos
    Given path '/'
    And request { "description": "Falta el campo name" }
    When method POST
    Then status 400
    And match response.message contains 'name'

  @validation
  Scenario: Rechazar recurso inexistente
    Given path '/inexistente-9999'
    When method GET
    Then status 404
