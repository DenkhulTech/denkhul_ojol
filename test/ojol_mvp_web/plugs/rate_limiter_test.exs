defmodule OjolMvpWeb.Plugs.RateLimiterTest do
  use OjolMvpWeb.ConnCase, async: true

  alias OjolMvpWeb.Plugs.RateLimiter

  setup do
    # Clear rate limit buckets before each test
    Hammer.delete_buckets("api:127.0.0.1")
    :ok
  end

  describe "rate limiting" do
    test "allows requests under limit" do
      conn = build_conn(:get, "/")

      # Should pass with low limit for testing
      result_conn = RateLimiter.call(conn, limit: 5, window: 60_000)

      refute result_conn.halted
    end

    test "blocks requests over limit" do
      conn = build_conn(:get, "/")
      opts = [limit: 2, window: 60_000]

      # First two requests should pass
      conn1 = RateLimiter.call(conn, opts)
      refute conn1.halted

      conn2 = RateLimiter.call(conn, opts)
      refute conn2.halted

      # Third request should be blocked
      conn3 = RateLimiter.call(conn, opts)
      assert conn3.halted
      assert conn3.status == 429
    end

    test "uses user ID when authenticated" do
      user = insert(:user)

      conn =
        build_conn(:get, "/")
        |> Guardian.Plug.sign_in(user)

      # Should use user-based identifier
      result_conn = RateLimiter.call(conn, limit: 5, window: 60_000)
      refute result_conn.halted
    end
  end
end
