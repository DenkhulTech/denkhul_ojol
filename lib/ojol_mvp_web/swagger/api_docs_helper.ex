defmodule OjolMvpWeb.ApiDocsHelper do
  @moduledoc """
  Helper functions for API documentation generation and validation
  """

  @doc """
  Generate API documentation in different formats
  """
  def generate_docs(format \\ :json) do
    spec = OjolMvpWeb.SwaggerSpec.spec()

    case format do
      :json -> Jason.encode!(spec, pretty: true)
      :yaml -> yaml_encode(spec)
      :html -> generate_html_docs(spec)
      _ -> {:error, "Unsupported format"}
    end
  end

  @doc """
  Validate OpenAPI specification
  """
  def validate_spec do
    spec = OjolMvpWeb.SwaggerSpec.spec()

    with :ok <- validate_openapi_version(spec),
         :ok <- validate_info(spec),
         :ok <- validate_paths(spec),
         :ok <- validate_components(spec) do
      {:ok, "Specification is valid"}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generate Postman collection from OpenAPI spec
  """
  def generate_postman_collection do
    spec = OjolMvpWeb.SwaggerSpec.spec()

    collection = %{
      info: %{
        _postman_id: UUID.uuid4(),
        name: spec.info.title,
        description: spec.info.description,
        schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
      },
      item: generate_postman_items(spec.paths),
      auth: %{
        type: "bearer",
        bearer: [
          %{
            key: "token",
            value: "{{jwt_token}}",
            type: "string"
          }
        ]
      },
      variable: [
        %{
          key: "base_url",
          value: "https://api.ojol-mvp.com/api",
          type: "string"
        },
        %{
          key: "jwt_token",
          value: "",
          type: "string"
        }
      ]
    }

    Jason.encode!(collection, pretty: true)
  end

  @doc """
  Generate cURL examples for all endpoints
  """
  def generate_curl_examples do
    spec = OjolMvpWeb.SwaggerSpec.spec()
    base_url = List.first(spec.servers).url

    spec.paths
    |> Enum.flat_map(fn {path, methods} ->
      Enum.map(methods, fn {method, operation} ->
        generate_curl_example(base_url, path, method, operation)
      end)
    end)
  end

  @doc """
  Get API statistics
  """
  def get_api_stats do
    spec = OjolMvpWeb.SwaggerSpec.spec()

    paths = spec.paths
    total_endpoints = paths |> Enum.flat_map(fn {_, methods} -> Map.keys(methods) end) |> length()

    public_endpoints = count_public_endpoints(paths)
    protected_endpoints = total_endpoints - public_endpoints

    tags = extract_all_tags(paths)

    %{
      total_endpoints: total_endpoints,
      public_endpoints: public_endpoints,
      protected_endpoints: protected_endpoints,
      total_paths: map_size(paths),
      tags: tags,
      schemas: map_size(spec.components.schemas),
      openapi_version: spec.openapi
    }
  end

  # Private functions

  defp yaml_encode(data) do
    # Simple YAML encoding - you might want to use a proper YAML library
    data
    |> Jason.encode!()
    |> Jason.decode!()
    |> yaml_encode_recursive("", 0)
  end

  defp yaml_encode_recursive(data, acc, indent) when is_map(data) do
    data
    |> Enum.reduce(acc, fn {key, value}, acc ->
      spaces = String.duplicate("  ", indent)
      acc <> spaces <> "#{key}:\n" <> yaml_encode_recursive(value, "", indent + 1)
    end)
  end

  defp yaml_encode_recursive(data, acc, indent) when is_list(data) do
    data
    |> Enum.with_index()
    |> Enum.reduce(acc, fn {value, _index}, acc ->
      spaces = String.duplicate("  ", indent)
      acc <> spaces <> "- " <> yaml_encode_recursive(value, "", indent + 1)
    end)
  end

  defp yaml_encode_recursive(data, _acc, _indent) when is_binary(data) do
    if String.contains?(data, "\n") do
      "|\n" <> String.replace(data, "\n", "\n  ")
    else
      "\"#{data}\"\n"
    end
  end

  defp yaml_encode_recursive(data, _acc, _indent), do: "#{data}\n"

  defp generate_html_docs(spec) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>#{spec.info.title} - API Documentation</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        h2 { color: #666; border-bottom: 1px solid #ddd; padding-bottom: 10px; }
        .endpoint { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .method { font-weight: bold; padding: 2px 8px; border-radius: 3px; color: white; }
        .get { background-color: #61affe; }
        .post { background-color: #49cc90; }
        .put { background-color: #fca130; }
        .delete { background-color: #f93e3e; }
        .path { font-family: monospace; font-size: 16px; margin: 5px 0; }
        .description { color: #666; margin: 10px 0; }
      </style>
    </head>
    <body>
      <h1>#{spec.info.title}</h1>
      <p>#{spec.info.description}</p>
      <p><strong>Version:</strong> #{spec.info.version}</p>

      <h2>Endpoints</h2>
      #{generate_html_endpoints(spec.paths)}
    </body>
    </html>
    """
  end

  defp generate_html_endpoints(paths) do
    paths
    |> Enum.map(fn {path, methods} ->
      methods
      |> Enum.map(fn {method, operation} ->
        """
        <div class="endpoint">
          <span class="method #{method}">#{String.upcase(to_string(method))}</span>
          <span class="path">#{path}</span>
          <div class="description">#{Map.get(operation, :summary, "")}</div>
        </div>
        """
      end)
      |> Enum.join("")
    end)
    |> Enum.join("")
  end

  defp generate_postman_items(paths) do
    paths
    |> Enum.flat_map(fn {path, methods} ->
      methods
      |> Enum.map(fn {method, operation} ->
        %{
          name: operation.summary || "#{String.upcase(to_string(method))} #{path}",
          request: %{
            method: String.upcase(to_string(method)),
            header: generate_postman_headers(operation),
            url: %{
              raw: "{{base_url}}#{path}",
              host: ["{{base_url}}"],
              path: String.split(path, "/") |> Enum.reject(&(&1 == ""))
            },
            body: generate_postman_body(operation)
          },
          response: []
        }
      end)
    end)
  end

  defp generate_postman_headers(operation) do
    headers = [%{key: "Content-Type", value: "application/json"}]

    if Map.has_key?(operation, :security) and length(operation.security) > 0 do
      [%{key: "Authorization", value: "Bearer {{jwt_token}}"} | headers]
    else
      headers
    end
  end

  defp generate_postman_body(operation) do
    case Map.get(operation, :requestBody) do
      nil -> %{mode: "raw", raw: ""}
      request_body ->
        content = get_in(request_body, [:content, "application/json", :schema])
        if content do
          %{
            mode: "raw",
            raw: generate_example_json(content),
            options: %{
              raw: %{language: "json"}
            }
          }
        else
          %{mode: "raw", raw: ""}
        end
    end
  end

  defp generate_example_json(schema) do
    case schema do
      %{"$ref" => _ref} -> "{}"
      %{properties: properties} ->
        example =
          properties
          |> Enum.map(fn {key, prop} ->
            value = Map.get(prop, :example, generate_example_value(prop))
            {key, value}
          end)
          |> Enum.into(%{})

        Jason.encode!(example, pretty: true)
      _ -> "{}"
    end
  end

  defp generate_example_value(%{type: "string"}), do: "example_string"
  defp generate_example_value(%{type: "integer"}), do: 123
  defp generate_example_value(%{type: "number"}), do: 123.45
  defp generate_example_value(%{type: "boolean"}), do: true
  defp generate_example_value(_), do: "example"

  defp generate_curl_example(base_url, path, method, operation) do
    method_upper = String.upcase(to_string(method))
    url = base_url <> path

    headers = []
    headers = if Map.has_key?(operation, :security) and length(operation.security) > 0 do
      ["-H \"Authorization: Bearer YOUR_JWT_TOKEN\"" | headers]
    else
      headers
    end

    headers = if Map.get(operation, :requestBody) do
      ["-H \"Content-Type: application/json\"" | headers]
    else
      headers
    end

    body = case Map.get(operation, :requestBody) do
      nil -> ""
      _request_body -> " \\\n  -d '{\"example\": \"data\"}'"
    end

    header_string = Enum.join(headers, " \\\n  ")

    """
    # #{operation.summary || "#{method_upper} #{path}"}
    curl -X #{method_upper} \\\n  #{header_string} \\\n  \"#{url}\"#{body}
    """
  end

  defp validate_openapi_version(%{openapi: version}) when is_binary(version), do: :ok
  defp validate_openapi_version(_), do: {:error, "Missing or invalid OpenAPI version"}

  defp validate_info(%{info: %{title: title, version: version}})
    when is_binary(title) and is_binary(version), do: :ok
  defp validate_info(_), do: {:error, "Missing or invalid info section"}

  defp validate_paths(%{paths: paths}) when is_map(paths), do: :ok
  defp validate_paths(_), do: {:error, "Missing or invalid paths section"}

  defp validate_components(%{components: components}) when is_map(components), do: :ok
  defp validate_components(_), do: {:error, "Missing or invalid components section"}

  defp count_public_endpoints(paths) do
    paths
    |> Enum.flat_map(fn {_path, methods} ->
      methods
      |> Enum.map(fn {_method, operation} ->
        not Map.has_key?(operation, :security) or length(Map.get(operation, :security, [])) == 0
      end)
    end)
    |> Enum.count(& &1)
  end

  defp extract_all_tags(paths) do
    paths
    |> Enum.flat_map(fn {_path, methods} ->
      methods
      |> Enum.flat_map(fn {_method, operation} ->
        Map.get(operation, :tags, [])
      end)
    end)
    |> Enum.uniq()
  end
end
