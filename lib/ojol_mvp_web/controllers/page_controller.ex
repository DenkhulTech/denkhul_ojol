defmodule OjolMvpWeb.PageController do
  use OjolMvpWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
