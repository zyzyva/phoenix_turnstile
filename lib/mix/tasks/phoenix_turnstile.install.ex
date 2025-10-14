defmodule Mix.Tasks.PhoenixTurnstile.Install do
  @moduledoc """
  Installs PhoenixTurnstile into a Phoenix application.

  This task uses Igniter to intelligently modify your application:

  - Adds Turnstile configuration to config files
  - Updates Content Security Policy to allow Turnstile domains
  - Copies the JavaScript hook to your assets directory
  - Registers the hook in your app.js

  ## Usage

      mix igniter.install phoenix_turnstile

  Or if running directly:

      mix phoenix_turnstile.install

  ## What Gets Installed

  ### Configuration (config/config.exs and config/runtime.exs)

  **Development (config.exs):**
  ```elixir
  # Cloudflare test keys - work on localhost without configuration
  config :phoenix_turnstile,
    site_key: "1x00000000000000000000AA",
    secret_key: "1x0000000000000000000000000000000AA"
  ```

  **Production (runtime.exs):**
  ```elixir
  # Environment variables for production keys
  config :phoenix_turnstile,
    site_key: System.get_env("TURNSTILE_SITE_KEY"),
    secret_key: System.get_env("TURNSTILE_SECRET_KEY")
  ```

  ### CSP Headers (router.ex)
  Adds these domains to your Content Security Policy:
  - `script-src`: https://challenges.cloudflare.com, https://*.cloudflare.com
  - `frame-src`: https://challenges.cloudflare.com, https://*.cloudflare.com
  - `style-src`: https://challenges.cloudflare.com
  - `connect-src`: https://challenges.cloudflare.com, https://*.cloudflare.com

  ### JavaScript Hook (assets/js/turnstile_hook.js)
  Copies the Turnstile LiveView hook to your assets directory.

  ### Hook Registration (assets/js/app.js)
  Adds import and registration of the TurnstileHook.

  ## After Installation

  The library works out of the box with Cloudflare test keys for local development!

  1. Use in your LiveView (avoid id="turnstile" to prevent naming collision):
     ```heex
     <PhoenixTurnstile.Components.widget id="turnstile-widget" />
     ```

  2. Handle the callback:
     ```elixir
     def handle_event("turnstile_callback", %{"token" => token}, socket) do
       case PhoenixTurnstile.verify_token(token) do
         {:ok, true} -> # verified
         _ -> # failed or bypassed
       end
     end
     ```

  3. (Optional) For production, set environment variables:
     ```
     export TURNSTILE_SITE_KEY="your_production_site_key"
     export TURNSTILE_SECRET_KEY="your_production_secret_key"
     ```
     Get your production keys from: https://dash.cloudflare.com/

  ## Important Notes

  - **DO NOT use id="turnstile"** - it creates a naming collision with window.turnstile
  - Use id="turnstile-widget" or any other unique ID instead
  - Test keys work on localhost without any domain configuration
  - Production keys are only used when MIX_ENV=prod
  """

  use Igniter.Mix.Task

  alias Igniter.Project.Config
  alias Rewrite.Source

  @shortdoc "Installs PhoenixTurnstile into your Phoenix application"

  # Constants for Turnstile domains (used in CSP warning)
  @cloudflare_domain "https://challenges.cloudflare.com"
  @cloudflare_wildcard "https://*.cloudflare.com"

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :phoenix_turnstile,
      adds_deps: [],
      installs: [],
      example: "mix igniter.install phoenix_turnstile"
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> add_configuration()
    |> update_csp_headers()
    |> copy_javascript_hook()
    |> register_hook_in_app_js()
  end

  # Add Turnstile configuration
  # config.exs: Hardcoded test keys (for dev and test)
  # runtime.exs: Environment variables (for prod only)
  defp add_configuration(igniter) do
    igniter
    |> add_dev_test_config()
    |> add_prod_runtime_config()
  end

  defp add_dev_test_config(igniter) do
    # Add hardcoded test keys to config.exs
    Config.configure(
      igniter,
      "config.exs",
      :phoenix_turnstile,
      [:site_key],
      "1x00000000000000000000AA"
    )
    |> Config.configure(
      "config.exs",
      :phoenix_turnstile,
      [:secret_key],
      "1x0000000000000000000000000000000AA"
    )
  end

  defp add_prod_runtime_config(igniter) do
    # Manually add config inside the `if config_env() == :prod do` block in runtime.exs
    runtime_path = "config/runtime.exs"

    Igniter.update_file(igniter, runtime_path, fn source ->
      content = Source.get(source, :content)

      # Check if already configured
      if String.contains?(content, ":phoenix_turnstile") do
        source
      else
        updated_content = add_turnstile_to_prod_block(content)
        Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_turnstile_to_prod_block(content) do
    turnstile_config = """

      # Turnstile configuration for production
      config :phoenix_turnstile,
        site_key: System.get_env("TURNSTILE_SITE_KEY"),
        secret_key: System.get_env("TURNSTILE_SECRET_KEY")
    """

    # Find the `if config_env() == :prod do` block and add config after it
    # Handle variations in whitespace and line endings
    content
    |> String.replace(
      ~r/(if\s+config_env\(\)\s*==\s*:prod\s+do\s*\n)/,
      "\\1#{turnstile_config}\n"
    )
  end

  # Update CSP headers in router to allow Turnstile domains
  defp update_csp_headers(igniter) do
    app_name = Igniter.Project.Application.app_name(igniter)
    router_path = "lib/#{app_name}_web/router.ex"

    # For now, just add a warning about CSP configuration
    # Users will need to manually add CSP headers if they use them
    add_csp_warning(igniter, router_path)
  end

  defp add_csp_warning(igniter, router_path) do
    Igniter.add_warning(
      igniter,
      """
      Could not automatically update Content Security Policy headers.

      Please manually add these domains to your CSP configuration in #{router_path}:

      script-src: #{@cloudflare_domain} #{@cloudflare_wildcard}
      frame-src: #{@cloudflare_domain} #{@cloudflare_wildcard}
      style-src: #{@cloudflare_domain}
      connect-src: #{@cloudflare_domain} #{@cloudflare_wildcard}
      child-src: #{@cloudflare_domain} #{@cloudflare_wildcard}
      """
    )
  end

  # Copy the JavaScript hook file to assets/js/
  defp copy_javascript_hook(igniter) do
    source_path = Application.app_dir(:phoenix_turnstile, ["priv", "static", "turnstile_hook.js"])
    dest_path = "assets/js/turnstile_hook.js"

    case File.read(source_path) do
      {:ok, content} ->
        Igniter.create_new_file(igniter, dest_path, content)

      _ ->
        Igniter.add_warning(
          igniter,
          "Could not copy turnstile_hook.js. Please copy it manually from the phoenix_turnstile package."
        )
    end
  end

  # Register the hook in app.js
  defp register_hook_in_app_js(igniter) do
    app_js_path = "assets/js/app.js"
    import_line = "import TurnstileHook from \"./turnstile_hook\"\n"

    Igniter.update_file(igniter, app_js_path, fn source ->
      content = Source.get(source, :content)

      updated_content =
        if String.contains?(content, "turnstile_hook") do
          content
        else
          content
          |> add_import_line(import_line)
          |> add_to_hooks_object()
        end

      Source.update(source, :content, updated_content)
    end)
  end

  defp add_import_line(content, import_line) do
    # Find the last import statement and add after it
    lines = String.split(content, "\n")

    {before_imports, after_imports} =
      Enum.split_while(lines, fn line ->
        !String.starts_with?(String.trim(line), "import ")
      end)

    {imports, rest} =
      Enum.split_while(after_imports, fn line ->
        String.starts_with?(String.trim(line), "import ") or String.trim(line) == ""
      end)

    (before_imports ++ imports ++ [import_line] ++ rest)
    |> Enum.join("\n")
  end

  defp add_to_hooks_object(content) do
    cond do
      # Case 1: hooks object already exists - add TurnstileHook to it
      String.contains?(content, "hooks:") ->
        content
        |> String.replace(
          ~r/(hooks:\s*\{)/,
          "\\1TurnstileHook, "
        )

      # Case 2: LiveSocket config exists but no hooks - add hooks parameter
      Regex.match?(~r/new\s+LiveSocket\s*\([^)]+,\s*\{/, content) ->
        content
        |> String.replace(
          ~r/(new\s+LiveSocket\s*\([^)]+,\s*\{)/,
          "\\1\n  hooks: {TurnstileHook},"
        )

      # Case 3: No config object - create one with hooks
      Regex.match?(~r/new\s+LiveSocket\s*\([^)]+\)/, content) ->
        content
        |> String.replace(
          ~r/(new\s+LiveSocket\s*\()([^,]+),\s*([^,]+)\)/,
          "\\1\\2, \\3, {\n  hooks: {TurnstileHook}\n})"
        )

      true ->
        content
    end
  end
end
