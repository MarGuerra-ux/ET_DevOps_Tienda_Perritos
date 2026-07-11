Feature: Health Check API

Scenario: Verificar que el servicio está operativo

    Given url baseUrl
    And path 'api', 'health'

    When method GET

    Then status 200

    And match response.status == 'ok'
    And match response.message contains 'Backend'