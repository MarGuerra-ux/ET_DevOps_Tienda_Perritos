Feature: Validar estructura JSON de productos

Scenario: Validar formato del listado de productos

    Given url baseUrl
    And path 'api', 'productos'

    When method GET

    Then status 200

    And match each response ==
    """
    {
      id: '#number',
      nombre: '#string',
      descripcion: '#string',
      precio: '#string',
      stock: '#number'
    }
    """