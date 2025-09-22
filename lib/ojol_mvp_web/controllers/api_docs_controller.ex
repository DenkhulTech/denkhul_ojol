defmodule OjolMvpWeb.ApiDocsController do
  use OjolMvpWeb, :controller

  def index(conn, _params) do
    swagger_spec = OjolMvpWeb.SwaggerSpec.spec()

    conn
    |> put_resp_header("content-type", "application/json")
    |> json(swagger_spec)
  end

  def swagger_ui(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html")
    |> put_resp_header("cache-control", "no-cache")
    |> send_resp(200, """
    |> send_resp(200, """
    <!DOCTYPE html>
    <html>
    <head>
      <title>OjolMvp API Documentation</title>
      <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui.css" />
      <style>
        html {
          box-sizing: border-box;
          overflow: -moz-scrollbars-vertical;
          overflow-y: scroll;
        }
        *, *:before, *:after {
          box-sizing: inherit;
        }
        body {
          margin:0;
          background: #fafafa;
        }
      </style>
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-bundle.js"></script>
      <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-standalone-preset.js"></script>
      <script>
        window.onload = function() {
          const ui = SwaggerUIBundle({
            url: '/docs',
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
          })
        }
      </script>
    </body>
    </html>
    """)
  end
end
