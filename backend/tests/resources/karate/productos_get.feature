Feature: Obtener productos

Scenario: Obtener listado de productos

    Given url baseUrl
    And path 'api', 'productos'

    When method GET

    Then status 200

    And match response == '#[]'