defmodule PhoenixTurnstileTest do
  use ExUnit.Case, async: true
  import PhoenixTurnstile.ConfigHelper

  describe "version/0" do
    test "returns the library version" do
      assert PhoenixTurnstile.version() == "0.1.0"
    end
  end

  describe "enabled?/0" do
    test "delegates to Verification.enabled?/0" do
      # Test when disabled
      with_temp_config([site_key: nil, secret_key: nil], fn ->
        refute PhoenixTurnstile.enabled?()
      end)

      # Test when enabled
      with_temp_config([site_key: "test-key", secret_key: "test-secret"], fn ->
        assert PhoenixTurnstile.enabled?()
      end)
    end
  end

  describe "site_key/0" do
    test "delegates to Verification.site_key/0" do
      with_temp_config([site_key: "my-site-key"], fn ->
        assert PhoenixTurnstile.site_key() == "my-site-key"
      end)

      with_temp_config([site_key: nil], fn ->
        assert PhoenixTurnstile.site_key() == nil
      end)
    end
  end

  describe "verify_token/1" do
    test "delegates to Verification.verify_token/1" do
      # Test with bypass token
      assert {:ok, true} = PhoenixTurnstile.verify_token("bypass-test")

      # Test with invalid input
      assert {:error, "Invalid token"} = PhoenixTurnstile.verify_token(nil)
    end

    test "handles various token types" do
      with_temp_config([secret_key: nil], fn ->
        # All should succeed when no secret key (development mode)
        assert {:ok, true} = PhoenixTurnstile.verify_token("any-token")
        assert {:ok, true} = PhoenixTurnstile.verify_token("bypass-reason")
      end)
    end
  end
end
