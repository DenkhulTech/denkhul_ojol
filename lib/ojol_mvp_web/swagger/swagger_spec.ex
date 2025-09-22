defmodule OjolMvpWeb.SwaggerSpec do
  @moduledoc """
  Swagger/OpenAPI specification for OjolMvp API
  """

  def spec do
    %{
      openapi: "3.0.3",
      info: %{
        title: "OjolMvp API",
        description: """
        API untuk aplikasi ride-hailing OjolMvp.

        ## Authentication
        Most endpoints require JWT Bearer token authentication.

        ## Rate Limiting
        - Public endpoints: 100 requests per minute per IP
        - Protected endpoints: 200 requests per minute per user

        ## Phone Number Format
        All phone numbers must follow Indonesian format: +62XXXXXXXXX
        """,
        version: "1.0.0",
        contact: %{
          name: "OjolMvp API Support",
          email: "api@ojol-mvp.com"
        }
      },
      servers: [
        %{
          url: "https://api.ojol-mvp.com/api",
          description: "Production server"
        },
        %{
          url: "http://localhost:4000/api",
          description: "Development server"
        }
      ],
      components: %{
        securitySchemes: %{
          bearerAuth: %{
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT"
          }
        },
        schemas: schemas()
      },
      security: [],
      paths: paths()
    }
  end

  defp schemas do
    %{
      User: %{
        type: "object",
        properties: %{
          id: %{type: "integer", example: 1},
          name: %{type: "string", example: "John Doe"},
          phone: %{type: "string", pattern: "^\\+62\\d{9,12}$", example: "+62812345678901"},
          type: %{type: "string", enum: ["customer", "driver"], example: "customer"},
          latitude: %{type: "number", format: "float", example: -7.7956},
          longitude: %{type: "number", format: "float", example: 110.3695},
          is_available: %{type: "boolean", example: true},
          average_rating: %{type: "number", format: "float", example: 4.8},
          total_ratings: %{type: "integer", example: 25},
          inserted_at: %{type: "string", format: "date-time"},
          updated_at: %{type: "string", format: "date-time"}
        }
      },
      UserCreate: %{
        type: "object",
        required: ["user"],
        properties: %{
          user: %{
            type: "object",
            required: ["name", "phone", "password", "type"],
            properties: %{
              name: %{type: "string", example: "John Doe"},
              phone: %{type: "string", pattern: "^\\+62\\d{9,12}$", example: "+62812345678901"},
              password: %{type: "string", minLength: 6, example: "password123"},
              type: %{type: "string", enum: ["customer", "driver"], example: "customer"}
            }
          }
        }
      },
      UserUpdate: %{
        type: "object",
        required: ["user"],
        properties: %{
          user: %{
            type: "object",
            properties: %{
              name: %{type: "string", example: "Updated Name"},
              is_available: %{type: "boolean", example: false}
            }
          }
        }
      },
      LocationUpdate: %{
        type: "object",
        required: ["latitude", "longitude"],
        properties: %{
          latitude: %{type: "number", format: "float", minimum: -90, maximum: 90, example: -7.7956},
          longitude: %{type: "number", format: "float", minimum: -180, maximum: 180, example: 110.3695}
        }
      },
      LoginRequest: %{
        type: "object",
        required: ["phone", "password"],
        properties: %{
          phone: %{type: "string", pattern: "^\\+62\\d{9,12}$", example: "+62812345678901"},
          password: %{type: "string", example: "password123"}
        }
      },
      Order: %{
        type: "object",
        properties: %{
          id: %{type: "integer", example: 11},
          status: %{type: "string", enum: ["pending", "accepted", "in_progress", "completed", "cancelled"], example: "pending"},
          pickup_address: %{type: "string", example: "Jl. Malioboro No. 123, Yogyakarta"},
          destination_address: %{type: "string", example: "Jl. Solo-Yogya Km. 10, Klaten"},
          pickup_lat: %{type: "number", format: "float", example: -7.7956},
          pickup_lng: %{type: "number", format: "float", example: 110.3695},
          destination_lat: %{type: "number", format: "float", example: -7.7065},
          destination_lng: %{type: "number", format: "float", example: 110.6056},
          distance_km: %{type: "number", format: "float", example: 31.33},
          estimated_duration: %{type: "integer", example: 27},
          total_fare: %{type: "integer", example: 98977},
          notes: %{type: "string", example: "Tunggu di depan pintu masuk utama"},
          route_geometry: %{type: "string", nullable: true},
          customer: %{"$ref": "#/components/schemas/UserMinimal"},
          driver: %{oneOf: [%{"$ref": "#/components/schemas/UserMinimal"}, %{type: "null"}]},
          is_my_order: %{type: "boolean", example: true},
          is_assigned_to_me: %{type: "boolean", example: false},
          distance_from_driver: %{type: "number", format: "float", example: 2.1},
          created_at: %{type: "string", format: "date-time"},
          updated_at: %{type: "string", format: "date-time"}
        }
      },
      OrderCreate: %{
        type: "object",
        required: ["order"],
        properties: %{
          order: %{
            type: "object",
            required: ["pickup_address", "pickup_lat", "pickup_lng", "destination_address", "destination_lat", "destination_lng"],
            properties: %{
              pickup_address: %{type: "string", example: "Jl. Malioboro No. 123, Yogyakarta"},
              pickup_lat: %{type: "number", format: "float", example: -7.7956},
              pickup_lng: %{type: "number", format: "float", example: 110.3695},
              destination_address: %{type: "string", example: "Jl. Solo-Yogya Km. 10, Klaten"},
              destination_lat: %{type: "number", format: "float", example: -7.7065},
              destination_lng: %{type: "number", format: "float", example: 110.6056},
              notes: %{type: "string", example: "Tunggu di depan pintu masuk utama"}
            }
          }
        }
      },
      OrderUpdate: %{
        type: "object",
        required: ["order"],
        properties: %{
          order: %{
            type: "object",
            properties: %{
              notes: %{type: "string", example: "Updated pickup instructions"}
            }
          }
        }
      },
      Rating: %{
        type: "object",
        properties: %{
          id: %{type: "integer", example: 1},
          rating: %{type: "integer", minimum: 1, maximum: 5, example: 5},
          comment: %{type: "string", example: "Driver sangat ramah dan cepat"},
          order_id: %{type: "integer", example: 11},
          reviewer_name: %{type: "string", example: "John Customer"},
          created_at: %{type: "string", format: "date-time"}
        }
      },
      RatingCreate: %{
        type: "object",
        required: ["rating"],
        properties: %{
          rating: %{
            type: "object",
            required: ["rating", "rated_user_id", "order_id", "reviewer_type"],
            properties: %{
              rating: %{type: "integer", minimum: 1, maximum: 5, example: 5},
              comment: %{type: "string", example: "Driver sangat ramah dan cepat"},
              rated_user_id: %{type: "integer", example: 2},
              order_id: %{type: "integer", example: 11},
              reviewer_type: %{type: "string", enum: ["customer", "driver"], example: "customer"}
            }
          }
        }
      },
      RatingUpdate: %{
        type: "object",
        required: ["rating"],
        properties: %{
          rating: %{
            type: "object",
            properties: %{
              rating: %{type: "integer", minimum: 1, maximum: 5, example: 4},
              comment: %{type: "string", example: "Updated comment"}
            }
          }
        }
      },
      UserMinimal: %{
        type: "object",
        properties: %{
          id: %{type: "integer", example: 1},
          name: %{type: "string", example: "John Doe"},
          phone: %{type: "string", example: "+62812345678901"},
          type: %{type: "string", enum: ["customer", "driver"], example: "customer"}
        }
      },
      Pagination: %{
        type: "object",
        properties: %{
          page: %{type: "integer", example: 1},
          limit: %{type: "integer", example: 10},
          total_count: %{type: "integer", example: 25},
          total_pages: %{type: "integer", example: 3}
        }
      },
      AuthResponse: %{
        type: "object",
        properties: %{
          message: %{type: "string", example: "Login successful"},
          token: %{type: "string", example: "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9..."},
          user: %{"$ref": "#/components/schemas/User"}
        }
      },
      ErrorResponse: %{
        type: "object",
        properties: %{
          error: %{type: "string", example: "Invalid or expired token"}
        }
      },
      SuccessResponse: %{
        type: "object",
        properties: %{
          message: %{type: "string", example: "Operation completed successfully"}
        }
      },
      DataResponse: %{
        type: "object",
        properties: %{
          data: %{type: "object"},
          message: %{type: "string", example: "Data retrieved successfully"}
        }
      },
      OrderListResponse: %{
        type: "object",
        properties: %{
          data: %{
            type: "array",
            items: %{"$ref": "#/components/schemas/Order"}
          },
          pagination: %{"$ref": "#/components/schemas/Pagination"}
        }
      },
      RatingListResponse: %{
        type: "object",
        properties: %{
          data: %{
            type: "array",
            items: %{"$ref": "#/components/schemas/Rating"}
          }
        }
      }
    }
  end

  defp paths do
    %{
      "/auth/register" => %{
        post: %{
          tags: ["Authentication"],
          summary: "Register a new user",
          description: "Create a new customer or driver account",
          requestBody: %{
            required: true,
            content: %{
              "application/json" => %{
                schema: %{"$ref": "#/components/schemas/UserCreate"}
              }
            }
          },
          responses: %{
            201 => %{
              description: "User created successfully",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/AuthResponse"}
                }
              }
            },
            400 => %{
              description: "Bad request - Missing required fields",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
                }
              }
            },
            422 => %{
              description: "Unprocessable entity - Validation error",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
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
          description: "Authenticate user and return JWT token",
          requestBody: %{
            required: true,
            content: %{
              "application/json" => %{
                schema: %{"$ref": "#/components/schemas/LoginRequest"}
              }
            }
          },
          responses: %{
            200 => %{
              description: "Login successful",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/AuthResponse"}
                }
              }
            },
            401 => %{
              description: "Invalid credentials",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
                }
              }
            }
          }
        }
      },
      "/auth/refresh" => %{
        post: %{
          tags: ["Authentication"],
          summary: "Refresh JWT token",
          description: "Get a new JWT token using current valid token",
          security: [%{bearerAuth: []}],
          responses: %{
            200 => %{
              description: "Token refreshed successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      token: %{type: "string", example: "new_jwt_token_here"}
                    }
                  }
                }
              }
            },
            401 => %{
              description: "Invalid or expired token",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
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
          description: "Invalidate the current JWT token",
          security: [%{bearerAuth: []}],
          responses: %{
            200 => %{
              description: "Logged out successfully",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/SuccessResponse"}
                }
              }
            },
            401 => %{
              description: "Invalid or expired token",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
                }
              }
            }
          }
        }
      },
      "/users" => %{
        post: %{
          tags: ["Users"],
          summary: "Create user (alternative registration)",
          description: "Create a new user account",
          requestBody: %{
            required: true,
            content: %{
              "application/json" => %{
                schema: %{"$ref": "#/components/schemas/UserCreate"}
              }
            }
          },
          responses: %{
            201 => %{
              description: "User created successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{"$ref": "#/components/schemas/User"},
                      message: %{type: "string", example: "User created successfully"}
                    }
                  }
                }
              }
            }
          }
        }
      },
      "/users/{user_id}/ratings" => %{
        get: %{
          tags: ["Users", "Ratings"],
          summary: "Get public ratings for a user",
          description: "Get all ratings for a specific user (public endpoint)",
          parameters: [
            %{
              name: "user_id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "User ID"
            }
          ],
          responses: %{
            200 => %{
              description: "User ratings retrieved successfully",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/RatingListResponse"}
                }
              }
            },
            404 => %{
              description: "User not found",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
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
          description: "Get the authenticated user's profile information",
          security: [%{bearerAuth: []}],
          responses: %{
            200 => %{
              description: "Profile retrieved successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{"$ref": "#/components/schemas/User"}
                    }
                  }
                }
              }
            },
            401 => %{
              description: "Unauthorized",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
                }
              }
            }
          }
        }
      },
      "/users/{id}" => %{
        get: %{
          tags: ["Users"],
          summary: "Get user by ID",
          description: "Get user information by ID (can only access your own data)",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "User ID"
            }
          ],
          responses: %{
            200 => %{
              description: "User retrieved successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{"$ref": "#/components/schemas/User"}
                    }
                  }
                }
              }
            },
            403 => %{
              description: "Forbidden - Can only access your own data",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
                }
              }
            }
          }
        },
        put: %{
          tags: ["Users"],
          summary: "Update user",
          description: "Update user information",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "User ID"
            }
          ],
          requestBody: %{
            required: true,
            content: %{
              "application/json" => %{
                schema: %{"$ref": "#/components/schemas/UserUpdate"}
              }
            }
          },
          responses: %{
            200 => %{
              description: "User updated successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{"$ref": "#/components/schemas/User"},
                      message: %{type: "string", example: "User updated successfully"}
                    }
                  }
                }
              }
            }
          }
        },
        delete: %{
          tags: ["Users"],
          summary: "Delete user account",
          description: "Delete the user's account",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "User ID"
            }
          ],
          responses: %{
            200 => %{
              description: "Account deleted successfully",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/SuccessResponse"}
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
          description: "Update the user's current location",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "User ID"
            }
          ],
          requestBody: %{
            required: true,
            content: %{
              "application/json" => %{
                schema: %{"$ref": "#/components/schemas/LocationUpdate"}
              }
            }
          },
          responses: %{
            200 => %{
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
                          latitude: %{type: "number", format: "float"},
                          longitude: %{type: "number", format: "float"},
                          updated_at: %{type: "string", format: "date-time"}
                        }
                      },
                      message: %{type: "string", example: "Location updated successfully"}
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
          summary: "Get my orders",
          description: "Get orders for the authenticated user with optional filtering and pagination",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "page",
              in: "query",
              schema: %{type: "integer", default: 1},
              description: "Page number"
            },
            %{
              name: "limit",
              in: "query",
              schema: %{type: "integer", default: 10, maximum: 50},
              description: "Items per page"
            },
            %{
              name: "status",
              in: "query",
              schema: %{type: "string", enum: ["pending", "accepted", "in_progress", "completed", "cancelled"]},
              description: "Filter by order status"
            }
          ],
          responses: %{
            200 => %{
              description: "Orders retrieved successfully",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/OrderListResponse"}
                }
              }
            }
          }
        },
        post: %{
          tags: ["Orders"],
          summary: "Create order",
          description: "Create a new ride order",
          security: [%{bearerAuth: []}],
          requestBody: %{
            required: true,
            content: %{
              "application/json" => %{
                schema: %{"$ref": "#/components/schemas/OrderCreate"}
              }
            }
          },
          responses: %{
            201 => %{
              description: "Order created successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{"$ref": "#/components/schemas/Order"},
                      message: %{type: "string", example: "Order created successfully"}
                    }
                  }
                }
              }
            }
          }
        }
      },
      "/orders/available" => %{
        get: %{
          tags: ["Orders", "Driver"],
          summary: "Get available orders (drivers only)",
          description: "Get available orders near driver's location",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "lat",
              in: "query",
              required: true,
              schema: %{type: "number", format: "float"},
              description: "Driver's latitude"
            },
            %{
              name: "lng",
              in: "query",
              required: true,
              schema: %{type: "number", format: "float"},
              description: "Driver's longitude"
            },
            %{
              name: "radius",
              in: "query",
              schema: %{type: "number", default: 10, maximum: 50},
              description: "Search radius in km"
            },
            %{
              name: "page",
              in: "query",
              schema: %{type: "integer", default: 1},
              description: "Page number"
            },
            %{
              name: "limit",
              in: "query",
              schema: %{type: "integer", default: 10, maximum: 50},
              description: "Items per page"
            }
          ],
          responses: %{
            200 => %{
              description: "Available orders retrieved successfully",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/OrderListResponse"}
                }
              }
            },
            403 => %{
              description: "Forbidden - Only drivers can access this endpoint",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
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
          description: "Get detailed information about a specific order",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "Order ID"
            }
          ],
          responses: %{
            200 => %{
              description: "Order details retrieved successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{"$ref": "#/components/schemas/Order"}
                    }
                  }
                }
              }
            },
            404 => %{
              description: "Order not found",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
                }
              }
            }
          }
        },
        put: %{
          tags: ["Orders"],
          summary: "Update order",
          description: "Update order information (only pending orders can be updated by customers)",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "Order ID"
            }
          ],
          requestBody: %{
            required: true,
            content: %{
              "application/json" => %{
                schema: %{"$ref": "#/components/schemas/OrderUpdate"}
              }
            }
          },
          responses: %{
            200 => %{
              description: "Order updated successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{"$ref": "#/components/schemas/Order"},
                      message: %{type: "string", example: "Order updated successfully"}
                    }
                  }
                }
              }
            }
          }
        },
        delete: %{
          tags: ["Orders"],
          summary: "Cancel order",
          description: "Cancel an existing order",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "Order ID"
            }
          ],
          responses: %{
            200 => %{
              description: "Order cancelled successfully",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/SuccessResponse"}
                }
              }
            }
          }
        }
      },
      "/orders/{id}/accept" => %{
        put: %{
          tags: ["Orders", "Driver"],
          summary: "Accept order (drivers only)",
          description: "Accept an available order as a driver",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "Order ID"
            }
          ],
          responses: %{
            200 => %{
              description: "Order accepted successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{
                        type: "object",
                        properties: %{
                          id: %{type: "integer"},
                          status: %{type: "string", example: "accepted"},
                          driver: %{"$ref": "#/components/schemas/UserMinimal"}
                        }
                      },
                      message: %{type: "string", example: "Order accepted successfully"}
                    }
                  }
                }
              }
            },
            403 => %{
              description: "Forbidden - Only drivers can accept orders",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
                }
              }
            },
            422 => %{
              description: "Order not available for acceptance",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
                }
              }
            }
          }
        }
      },
      "/orders/{id}/start" => %{
        put: %{
          tags: ["Orders", "Driver"],
          summary: "Start trip (assigned driver only)",
          description: "Start the trip for an accepted order",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "Order ID"
            }
          ],
          responses: %{
            200 => %{
              description: "Trip started successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{
                        type: "object",
                        properties: %{
                          id: %{type: "integer"},
                          status: %{type: "string", example: "in_progress"}
                        }
                      },
                      message: %{type: "string", example: "Trip started successfully"}
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
          tags: ["Orders", "Driver"],
          summary: "Complete trip (assigned driver only)",
          description: "Complete the trip for an in-progress order",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "Order ID"
            }
          ],
          responses: %{
            200 => %{
              description: "Trip completed successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{
                        type: "object",
                        properties: %{
                          id: %{type: "integer"},
                          status: %{type: "string", example: "completed"}
                        }
                      },
                      message: %{type: "string", example: "Trip completed successfully"}
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
          summary: "Get my ratings (given by me)",
          description: "Get ratings that the authenticated user has given to others",
          security: [%{bearerAuth: []}],
          responses: %{
            200 => %{
              description: "Ratings retrieved successfully",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/RatingListResponse"}
                }
              }
            }
          }
        },
        post: %{
          tags: ["Ratings"],
          summary: "Create rating",
          description: "Create a new rating for a user after completing an order",
          security: [%{bearerAuth: []}],
          requestBody: %{
            required: true,
            content: %{
              "application/json" => %{
                schema: %{"$ref": "#/components/schemas/RatingCreate"}
              }
            }
          },
          responses: %{
            201 => %{
              description: "Rating submitted successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{"$ref": "#/components/schemas/Rating"},
                      message: %{type: "string", example: "Rating submitted successfully"}
                    }
                  }
                }
              }
            }
          }
        }
      },
      "/ratings/received" => %{
        get: %{
          tags: ["Ratings"],
          summary: "Get received ratings",
          description: "Get ratings that the authenticated user has received from others",
          security: [%{bearerAuth: []}],
          responses: %{
            200 => %{
              description: "Received ratings retrieved successfully",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/RatingListResponse"}
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
          description: "Get detailed information about a specific rating",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "Rating ID"
            }
          ],
          responses: %{
            200 => %{
              description: "Rating details retrieved successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{"$ref": "#/components/schemas/Rating"}
                    }
                  }
                }
              }
            },
            404 => %{
              description: "Rating not found",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/ErrorResponse"}
                }
              }
            }
          }
        },
        put: %{
          tags: ["Ratings"],
          summary: "Update rating",
          description: "Update an existing rating",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "Rating ID"
            }
          ],
          requestBody: %{
            required: true,
            content: %{
              "application/json" => %{
                schema: %{"$ref": "#/components/schemas/RatingUpdate"}
              }
            }
          },
          responses: %{
            200 => %{
              description: "Rating updated successfully",
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{
                      data: %{"$ref": "#/components/schemas/Rating"},
                      message: %{type: "string", example: "Rating updated successfully"}
                    }
                  }
                }
              }
            }
          }
        },
        delete: %{
          tags: ["Ratings"],
          summary: "Delete rating",
          description: "Delete an existing rating",
          security: [%{bearerAuth: []}],
          parameters: [
            %{
              name: "id",
              in: "path",
              required: true,
              schema: %{type: "integer"},
              description: "Rating ID"
            }
          ],
          responses: %{
            200 => %{
              description: "Rating deleted successfully",
              content: %{
                "application/json" => %{
                  schema: %{"$ref": "#/components/schemas/SuccessResponse"}
                }
              }
            }
          }
        }
      }
    }
  end
end
