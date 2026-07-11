Feature: Crear producto

Scenario: Crear un nuevo producto

    * def nuevoProducto =
    """
    {
      "nombre": "Producto Karate",
      "descripcion": "Producto creado desde Karate",
      "precio": "5990.00",
      "stock": 10
    }
    """

    Given url baseUrl
    And path 'api', 'productos'
    And request nuevoProducto

    When method POST

    Then status 201

    And match response.nombre == nuevoProducto.nombre
    And match response.descripcion == nuevoProducto.descripcion
    And match response.precio == nuevoProducto.precio
    And match response.stock == nuevoProducto.stock