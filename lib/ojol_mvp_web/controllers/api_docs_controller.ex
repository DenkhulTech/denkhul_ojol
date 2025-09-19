defmodule OjolMvpWeb.ApiDocsController do
  use OjolMvpWeb, :controller

  def index(conn, _params) do
    swagger_spec = %{
      openapi: "3.0.3",
      info: %{
        title: "OjolMvp API",
        description:
          "API untuk aplikasi ride-hailing OjolMvp.\n\n## Authentication\nAPI menggunakan JWT Bearer token untuk autentikasi. Sertakan token di header:\n```\nAuthorization: Bearer <your-jwt-token>\n```\n\n## Rate Limiting\nEndpoint publik dibatasi untuk mencegah spam dan abuse.\n\n## User Types\n- **customer**: Pengguna yang memesan ojek\n- **driver**: Driver ojek yang menerima pesanan\n\n## Order Status Flow\n1. **pending** - Order baru dibuat, menunggu driver\n2. **accepted** - Driver menerima order\n3. **in_progress** - Perjalanan sedang berlangsung\n4. **completed** - Perjalanan selesai\n5. **cancelled** - Order dibatalkan",
        version: "1.0.0",
        contact: %{
          name: "OjolMvp API Support",
          email: "support@ojolmvp.com"
        }
      },
      servers: [
        %{
          url: "http://localhost:4000/api",
          description: "Development server"
        },
        %{
          url: "https://api.ojolmvp.com/api",
          description: "Production server"
        }
      ],
      components: %{
        securitySchemes: %{
          BearerAuth: %{
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT"
          }
        },
        schemas: %{
          User: %{
            type: "object",
            properties: %{
              id: %{type: "integer", example: 1},
              name: %{type: "string", example: "John Doe"},
              phone: %{type: "string", pattern: "^\\+62[0-9]{9,12}$", example: "+628123456789"},
              type: %{type: "string", enum: ["customer", "driver"], example: "customer"},
              latitude: %{type: "number", format: "decimal", example: -6.2088},
              longitude: %{type: "number", format: "decimal", example: 106.8456},
              is_available: %{type: "boolean", example: true},
              average_rating: %{type: "number", format: "decimal", example: 4.5},
              total_ratings: %{type: "integer", example: 25},
              created_at: %{type: "string", format: "date-time"},
              updated_at: %{type: "string", format: "date-time"}
            }
          },
          Order: %{
            type: "object",
            properties: %{
              id: %{type: "integer", example: 1},
              status: %{
                type: "string",
                enum: ["pending", "accepted", "in_progress", "completed", "cancelled"],
                example: "pending"
              },
              pickup_address: %{type: "string", example: "Jl. Sudirman No. 1, Jakarta"},
              destination_address: %{type: "string", example: "Jl. Thamrin No. 10, Jakarta"},
              pickup_lat: %{type: "number", format: "decimal", example: -6.2088},
              pickup_lng: %{type: "number", format: "decimal", example: 106.8456},
              destination_lat: %{type: "number", format: "decimal", example: -6.1944},
              destination_lng: %{type: "number", format: "decimal", example: 106.8229},
              distance_km: %{type: "number", format: "decimal", example: 5.2},
              price: %{type: "integer", example: 15000},
              notes: %{type: "string", example: "Mohon tunggu di lobby"},
              customer: %{"$ref": "#/components/schemas/UserInfo"},
              driver: %{"$ref": "#/components/schemas/UserInfo"},
              is_my_order: %{type: "boolean", example: true},
              is_assigned_to_me: %{type: "boolean", example: false},
              created_at: %{type: "string", format: "date-time"},
              updated_at: %{type: "string", format: "date-time"}
            }
          },
          Rating: %{
            type: "object",
            properties: %{
              id: %{type: "integer", example: 1},
              rating: %{type: "integer", minimum: 1, maximum: 5, example: 5},
              comment: %{type: "string", example: "Driver sangat ramah dan cepat"},
              reviewer_type: %{type: "string", enum: ["customer", "driver"], example: "customer"},
              order_id: %{type: "integer", example: 1},
              reviewer: %{"$ref": "#/components/schemas/UserInfo"},
              reviewee: %{"$ref": "#/components/schemas/UserInfo"},
              inserted_at: %{type: "string", format: "date-time"},
              updated_at: %{type: "string", format: "date-time"}
            }
          },
          UserInfo: %{
            type: "object",
            properties: %{
              id: %{type: "integer", example: 1},
              name: %{type: "string", example: "John Doe"},
              phone: %{type: "string", example: "+628123456789"},
              type: %{type: "string", enum: ["customer", "driver"], example: "customer"}
            }
          },
          CreateUserRequest: %{
            type: "object",
            required: ["name", "phone", "type", "password"],
            properties: %{
              name: %{type: "string", minLength: 2, maxLength: 50, example: "John Doe"},
              phone: %{type: "string", pattern: "^\\+62[0-9]{9,12}$", example: "+628123456789"},
              type: %{type: "string", enum: ["customer", "driver"], example: "customer"},
              password: %{type: "string", minLength: 6, maxLength: 128, example: "password123"}
            }
          },
          CreateOrderRequest: %{
            type: "object",
            required: [
              "pickup_address",
              "destination_address",
              "pickup_lat",
              "pickup_lng",
              "destination_lat",
              "destination_lng",
              "price"
            ],
            properties: %{
              pickup_address: %{
                type: "string",
                minLength: 5,
                maxLength: 255,
                example: "Jl. Sudirman No. 1, Jakarta"
              },
              destination_address: %{
                type: "string",
                minLength: 5,
                maxLength: 255,
                example: "Jl. Thamrin No. 10, Jakarta"
              },
              pickup_lat: %{
                type: "number",
                format: "decimal",
                minimum: -90,
                maximum: 90,
                example: -6.2088
              },
              pickup_lng: %{
                type: "number",
                format: "decimal",
                minimum: -180,
                maximum: 180,
                example: 106.8456
              },
              destination_lat: %{
                type: "number",
                format: "decimal",
                minimum: -90,
                maximum: 90,
                example: -6.1944
              },
              destination_lng: %{
                type: "number",
                format: "decimal",
                minimum: -180,
                maximum: 180,
                example: 106.8229
              },
              price: %{type: "integer", minimum: 1, maximum: 9_999_999, example: 15000},
              notes: %{type: "string", maxLength: 500, example: "Mohon tunggi di lobby"}
            }
          },
          CreateRatingRequest: %{
            type: "object",
            required: ["order_id", "reviewee_id", "rating", "comment", "reviewer_type"],
            properties: %{
              order_id: %{type: "integer", example: 1},
              reviewee_id: %{type: "integer", example: 2},
              rating: %{type: "integer", minimum: 1, maximum: 5, example: 5},
              comment: %{
                type: "string",
                minLength: 5,
                maxLength: 1000,
                example: "Driver sangat ramah dan cepat"
              },
              reviewer_type: %{type: "string", enum: ["customer", "driver"], example: "customer"}
            }
          },
          LoginRequest: %{
            type: "object",
            required: ["phone", "password"],
            properties: %{
              phone: %{type: "string", example: "+628123456789"},
              password: %{type: "string", example: "password123"}
            }
          },
          PaginationResponse: %{
            type: "object",
            properties: %{
              page: %{type: "integer", example: 1},
              limit: %{type: "integer", example: 10},
              total_count: %{type: "integer", example: 100},
              total_pages: %{type: "integer", example: 10}
            }
          },
          ErrorResponse: %{
            type: "object",
            properties: %{
              error: %{type: "string", example: "Invalid credentials"}
            }
          },
          SuccessResponse: %{
            type: "object",
            properties: %{
              message: %{type: "string", example: "Operation successful"},
              data: %{type: "object"}
            }
          }
        }
      },
      paths: %{
        "/auth/register" => %{
          post: %{
            tags: ["Authentication"],
            summary: "Register new user",
            requestBody: %{
              required: true,
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      user: %{"$ref" => "#/components/schemas/CreateUserRequest"}
                    }
                  }
                }
              }
            },
            responses: %{
              "201" => %{
                description: "User registered successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/User"},
                        message: %{type: "string", example: "User created successfully"}
                      }
                    }
                  }
                }
              },
              "400" => %{
                description: "Invalid input",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/ErrorResponse"}
                  }
                }
              }
            }
          }
        },
        "/auth/login" => %{
          post: %{
            tags: ["Authentication"],
            summary: "Login user",
            requestBody: %{
              required: true,
              content: %{
                "application/json" => %{
                  schema: %{"$ref" => "#/components/schemas/LoginRequest"}
                }
              }
            },
            responses: %{
              "200" => %{
                description: "Login successful",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        token: %{
                          type: "string",
                          example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                        },
                        user: %{"$ref" => "#/components/schemas/User"}
                      }
                    }
                  }
                }
              },
              "401" => %{
                description: "Invalid credentials",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/ErrorResponse"}
                  }
                }
              }
            }
          }
        },
        "/auth/logout" => %{
          post: %{
            tags: ["Authentication"],
            summary: "Logout user",
            security: [%{"BearerAuth" => []}],
            responses: %{
              "200" => %{
                description: "Logout successful",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/SuccessResponse"}
                  }
                }
              }
            }
          }
        },
        "/users" => %{
          post: %{
            tags: ["Users"],
            summary: "Create new user (public registration)",
            requestBody: %{
              required: true,
              content: %{
                "application/json" => %{
                  schema: %{"$ref" => "#/components/schemas/CreateUserRequest"}
                }
              }
            },
            responses: %{
              "201" => %{
                description: "User created successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/User"},
                        message: %{type: "string"}
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "/profile" => %{
          get: %{
            tags: ["Users"],
            summary: "Get current user profile",
            security: [%{"BearerAuth" => []}],
            responses: %{
              "200" => %{
                description: "User profile",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/User"}
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "/users/{id}" => %{
          get: %{
            tags: ["Users"],
            summary: "Get user by ID (own data only)",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            responses: %{
              "200" => %{
                description: "User data",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/User"}
                      }
                    }
                  }
                }
              },
              "403" => %{
                description: "Access denied",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/ErrorResponse"}
                  }
                }
              }
            }
          },
          put: %{
            tags: ["Users"],
            summary: "Update user (own data only)",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            requestBody: %{
              required: true,
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      user: %{
                        type: "object",
                        properties: %{
                          name: %{type: "string"},
                          phone: %{type: "string"},
                          password: %{type: "string"}
                        }
                      }
                    }
                  }
                }
              }
            },
            responses: %{
              "200" => %{
                description: "User updated successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/User"},
                        message: %{type: "string"}
                      }
                    }
                  }
                }
              }
            }
          },
          delete: %{
            tags: ["Users"],
            summary: "Delete user account (own account only)",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            responses: %{
              "200" => %{
                description: "Account deleted successfully",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/SuccessResponse"}
                  }
                }
              }
            }
          }
        },
        "/users/{id}/location" => %{
          put: %{
            tags: ["Users"],
            summary: "Update user location",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            requestBody: %{
              required: true,
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    required: ["latitude", "longitude"],
                    properties: %{
                      latitude: %{type: "number", format: "decimal", minimum: -90, maximum: 90},
                      longitude: %{type: "number", format: "decimal", minimum: -180, maximum: 180}
                    }
                  }
                }
              }
            },
            responses: %{
              "200" => %{
                description: "Location updated successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{
                          type: "object",
                          properties: %{
                            id: %{type: "integer"},
                            latitude: %{type: "number"},
                            longitude: %{type: "number"},
                            updated_at: %{type: "string", format: "date-time"}
                          }
                        },
                        message: %{type: "string"}
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "/orders" => %{
          get: %{
            tags: ["Orders"],
            summary: "Get user's orders",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "page",
                in: "query",
                schema: %{type: "integer", default: 1}
              },
              %{
                name: "limit",
                in: "query",
                schema: %{type: "integer", default: 10, maximum: 50}
              },
              %{
                name: "status",
                in: "query",
                schema: %{
                  type: "string",
                  enum: ["pending", "accepted", "in_progress", "completed", "cancelled"]
                }
              }
            ],
            responses: %{
              "200" => %{
                description: "List of user's orders",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{
                          type: "array",
                          items: %{"$ref" => "#/components/schemas/Order"}
                        },
                        pagination: %{"$ref" => "#/components/schemas/PaginationResponse"}
                      }
                    }
                  }
                }
              }
            }
          },
          post: %{
            tags: ["Orders"],
            summary: "Create new order (customers only)",
            security: [%{"BearerAuth" => []}],
            requestBody: %{
              required: true,
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      order: %{"$ref" => "#/components/schemas/CreateOrderRequest"}
                    }
                  }
                }
              }
            },
            responses: %{
              "201" => %{
                description: "Order created successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/Order"},
                        message: %{type: "string"}
                      }
                    }
                  }
                }
              },
              "403" => %{
                description: "Only customers can create orders",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/ErrorResponse"}
                  }
                }
              }
            }
          }
        },
        "/orders/available" => %{
          get: %{
            tags: ["Orders"],
            summary: "Get available orders for drivers",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "lat",
                in: "query",
                required: true,
                schema: %{type: "number", format: "decimal"}
              },
              %{
                name: "lng",
                in: "query",
                required: true,
                schema: %{type: "number", format: "decimal"}
              },
              %{
                name: "radius",
                in: "query",
                schema: %{type: "number", default: 10.0, maximum: 50}
              },
              %{
                name: "page",
                in: "query",
                schema: %{type: "integer", default: 1}
              },
              %{
                name: "limit",
                in: "query",
                schema: %{type: "integer", default: 10, maximum: 50}
              }
            ],
            responses: %{
              "200" => %{
                description: "List of available orders",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{
                          type: "array",
                          items: %{
                            allOf: [
                              %{"$ref" => "#/components/schemas/Order"},
                              %{
                                type: "object",
                                properties: %{
                                  distance_from_driver: %{
                                    type: "number",
                                    format: "decimal",
                                    example: 2.5
                                  }
                                }
                              }
                            ]
                          }
                        },
                        pagination: %{"$ref" => "#/components/schemas/PaginationResponse"}
                      }
                    }
                  }
                }
              },
              "403" => %{
                description: "Only drivers can view available orders",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/ErrorResponse"}
                  }
                }
              }
            }
          }
        },
        "/orders/{id}" => %{
          get: %{
            tags: ["Orders"],
            summary: "Get order details",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            responses: %{
              "200" => %{
                description: "Order details",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/Order"}
                      }
                    }
                  }
                }
              },
              "404" => %{
                description: "Order not found",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/ErrorResponse"}
                  }
                }
              }
            }
          },
          put: %{
            tags: ["Orders"],
            summary: "Update order (customers only, pending orders only)",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            requestBody: %{
              required: true,
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      order: %{
                        type: "object",
                        properties: %{
                          pickup_address: %{type: "string"},
                          destination_address: %{type: "string"},
                          pickup_lat: %{type: "number"},
                          pickup_lng: %{type: "number"},
                          destination_lat: %{type: "number"},
                          destination_lng: %{type: "number"},
                          price: %{type: "integer"},
                          notes: %{type: "string"}
                        }
                      }
                    }
                  }
                }
              }
            },
            responses: %{
              "200" => %{
                description: "Order updated successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/Order"},
                        message: %{type: "string"}
                      }
                    }
                  }
                }
              }
            }
          },
          delete: %{
            tags: ["Orders"],
            summary: "Cancel order (customers only)",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            responses: %{
              "200" => %{
                description: "Order cancelled successfully",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/SuccessResponse"}
                  }
                }
              }
            }
          }
        },
        "/orders/{id}/accept" => %{
          put: %{
            tags: ["Orders"],
            summary: "Accept order (drivers only)",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            responses: %{
              "200" => %{
                description: "Order accepted successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/Order"},
                        message: %{type: "string"}
                      }
                    }
                  }
                }
              },
              "422" => %{
                description: "Order not available",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/ErrorResponse"}
                  }
                }
              }
            }
          }
        },
        "/orders/{id}/start" => %{
          put: %{
            tags: ["Orders"],
            summary: "Start trip (assigned driver only)",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            responses: %{
              "200" => %{
                description: "Trip started successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/Order"},
                        message: %{type: "string"}
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "/orders/{id}/complete" => %{
          put: %{
            tags: ["Orders"],
            summary: "Complete trip (assigned driver only)",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            responses: %{
              "200" => %{
                description: "Trip completed successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/Order"},
                        message: %{type: "string"}
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "/ratings" => %{
          get: %{
            tags: ["Ratings"],
            summary: "Get ratings created by current user",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "page",
                in: "query",
                schema: %{type: "integer", default: 1}
              },
              %{
                name: "limit",
                in: "query",
                schema: %{type: "integer", default: 10, maximum: 100}
              }
            ],
            responses: %{
              "200" => %{
                description: "List of ratings created by user",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{
                          type: "array",
                          items: %{"$ref" => "#/components/schemas/Rating"}
                        },
                        pagination: %{"$ref" => "#/components/schemas/PaginationResponse"}
                      }
                    }
                  }
                }
              }
            }
          },
          post: %{
            tags: ["Ratings"],
            summary: "Create new rating",
            security: [%{"BearerAuth" => []}],
            requestBody: %{
              required: true,
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      rating: %{"$ref" => "#/components/schemas/CreateRatingRequest"}
                    }
                  }
                }
              }
            },
            responses: %{
              "201" => %{
                description: "Rating created successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/Rating"},
                        message: %{type: "string"}
                      }
                    }
                  }
                }
              },
              "403" => %{
                description: "Cannot rate - unauthorized or duplicate rating",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/ErrorResponse"}
                  }
                }
              }
            }
          }
        },
        "/ratings/received" => %{
          get: %{
            tags: ["Ratings"],
            summary: "Get ratings received by current user",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "page",
                in: "query",
                schema: %{type: "integer", default: 1}
              },
              %{
                name: "limit",
                in: "query",
                schema: %{type: "integer", default: 10, maximum: 100}
              }
            ],
            responses: %{
              "200" => %{
                description: "List of ratings received by user",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{
                          type: "array",
                          items: %{"$ref" => "#/components/schemas/Rating"}
                        },
                        stats: %{
                          type: "object",
                          properties: %{
                            average_rating: %{type: "number", format: "decimal", example: 4.5},
                            total_ratings: %{type: "integer", example: 25}
                          }
                        },
                        pagination: %{"$ref" => "#/components/schemas/PaginationResponse"}
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "/ratings/{id}" => %{
          get: %{
            tags: ["Ratings"],
            summary: "Get rating details",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            responses: %{
              "200" => %{
                description: "Rating details",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/Rating"}
                      }
                    }
                  }
                }
              }
            }
          },
          put: %{
            tags: ["Ratings"],
            summary: "Update rating (own rating only, within 24 hours)",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            requestBody: %{
              required: true,
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      rating: %{
                        type: "object",
                        properties: %{
                          rating: %{type: "integer", minimum: 1, maximum: 5},
                          comment: %{type: "string", minLength: 5, maxLength: 1000}
                        }
                      }
                    }
                  }
                }
              }
            },
            responses: %{
              "200" => %{
                description: "Rating updated successfully",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{"$ref" => "#/components/schemas/Rating"},
                        message: %{type: "string"}
                      }
                    }
                  }
                }
              }
            }
          },
          delete: %{
            tags: ["Ratings"],
            summary: "Delete rating (own rating only, within 1 hour)",
            security: [%{"BearerAuth" => []}],
            parameters: [
              %{
                name: "id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              }
            ],
            responses: %{
              "200" => %{
                description: "Rating deleted successfully",
                content: %{
                  "application/json" => %{
                    schema: %{"$ref" => "#/components/schemas/SuccessResponse"}
                  }
                }
              }
            }
          }
        },
        "/users/{user_id}/ratings" => %{
          get: %{
            tags: ["Ratings"],
            summary: "Get public ratings for a user (for checking driver/customer ratings)",
            parameters: [
              %{
                name: "user_id",
                in: "path",
                required: true,
                schema: %{type: "integer"}
              },
              %{
                name: "page",
                in: "query",
                schema: %{type: "integer", default: 1}
              },
              %{
                name: "limit",
                in: "query",
                schema: %{type: "integer", default: 10, maximum: 100}
              }
            ],
            responses: %{
              "200" => %{
                description: "Public ratings for user",
                content: %{
                  "application/json" => %{
                    schema: %{
                      type: "object",
                      properties: %{
                        data: %{
                          type: "array",
                          items: %{
                            type: "object",
                            properties: %{
                              id: %{type: "integer"},
                              rating: %{type: "integer"},
                              comment: %{type: "string"},
                              reviewer_name: %{type: "string", example: "J*** D***"},
                              inserted_at: %{type: "string", format: "date-time"}
                            }
                          }
                        },
                        stats: %{
                          type: "object",
                          properties: %{
                            average_rating: %{type: "number", format: "decimal", example: 4.5},
                            total_ratings: %{type: "integer", example: 25}
                          }
                        },
                        pagination: %{"$ref" => "#/components/schemas/PaginationResponse"}
                      }
                    }
                  }
                }
              }
            }
          }
        }
      },
      tags: %{
        Authentication: %{
          name: "Authentication",
          description: "User authentication endpoints"
        },
        Users: %{
          name: "Users",
          description: "User management endpoints"
        },
        Orders: %{
          name: "Orders",
          description: "Order/ride management endpoints"
        },
        Ratings: %{
          name: "Ratings",
          description: "Rating and review endpoints"
        }
      }
    }

    json(conn, swagger_spec)
  end

  def ui(conn, _params) do
    html(conn, """
    <!DOCTYPE html>
    <html>
    <head>
      <title>OjolMvp API Documentation</title>
      <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui.css" />
      <style>
        html { box-sizing: border-box; overflow: -moz-scrollbars-vertical; overflow-y: scroll; }
        *, *:before, *:after { box-sizing: inherit; }
        body { margin:0; background: #fafafa; }
      </style>
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-bundle.js"></script>
      <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-standalone-preset.js"></script>
      <script>
        window.onload = function() {
          const ui = SwaggerUIBundle({
            url: '/api-docs/spec.json',
            dom_id: '#swagger-ui',
            deepLinking: true,
            presets: [
              SwaggerUIBundle.presets.apis,
              SwaggerUIStandalonePreset
            ],
            plugins: [
              SwaggerUIBundle.plugins.DownloadUrl
            ],
            layout: "StandaloneLayout"
          });
        };
      </script>
    </body>
    </html>
    """)
  end
end
