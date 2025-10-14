defmodule PhoenixTurnstile.ConfigHelper do
  @moduledoc """
  Test helpers for managing application configuration in tests.
  """

  @doc """
  Temporarily sets configuration values for the duration of a test.

  Returns the original values so they can be restored.

  ## Examples

      setup do
        on_exit(fn -> restore_config(config) end)
        {:ok, config: with_config(site_key: "test", secret_key: "secret")}
      end
  """
  def with_config(opts) do
    original =
      Enum.map(opts, fn {key, _value} ->
        {key, Application.get_env(:phoenix_turnstile, key)}
      end)
      |> Map.new()

    Enum.each(opts, fn {key, value} ->
      Application.put_env(:phoenix_turnstile, key, value)
    end)

    original
  end

  @doc """
  Restores configuration values to their original state.
  """
  def restore_config(original_config) when is_map(original_config) do
    Enum.each(original_config, fn {key, value} ->
      Application.put_env(:phoenix_turnstile, key, value)
    end)
  end

  @doc """
  Runs a function with temporary configuration, then restores the original values.

  ## Examples

      with_temp_config([site_key: "test"], fn ->
        assert PhoenixTurnstile.site_key() == "test"
      end)
  """
  def with_temp_config(opts, fun) do
    original = with_config(opts)

    try do
      fun.()
    after
      restore_config(original)
    end
  end

  @doc """
  Sets up Turnstile as enabled with test keys.
  """
  def enable_turnstile do
    with_config(site_key: "test-site-key", secret_key: "test-secret-key")
  end

  @doc """
  Sets up Turnstile as disabled (no keys configured).
  """
  def disable_turnstile do
    with_config(site_key: nil, secret_key: nil)
  end
end
