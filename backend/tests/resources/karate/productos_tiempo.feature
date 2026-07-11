Feature: Validar tiempo de respuesta

Scenario: Verificar rendimiento de la API

    Given url baseUrl
    And path 'api', 'productos'

    When method GET

    Then status 200

    And assert responseTime < 2000