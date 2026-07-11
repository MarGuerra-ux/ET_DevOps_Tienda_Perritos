Feature: Buscar producto inexistente

Scenario: Consultar un producto que no existe

    Given url baseUrl
    And path 'api', 'productos', 999999

    When method GET

    Then status 404

    And match response.message == 'Producto no encontrado.'