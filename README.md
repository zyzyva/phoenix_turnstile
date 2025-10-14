# PhoenixTurnstile

A comprehensive Cloudflare Turnstile integration for Phoenix and LiveView applications with graceful failure handling that never blocks users.

## Features

- **Graceful Failure Handling** - Verification failures never block legitimate users
- **Automatic CSP Configuration** - Igniter-based installer handles Content Security Policy updates
- **Phoenix LiveView Components** - Drop-in components for easy widget rendering
- **JavaScript Hook** - Client-side widget management with automatic fallbacks
- **Bypass Mode** - Development-friendly bypass tokens for testing
- **Zero-Config Development** - Works out of the box without API keys
- **Comprehensive Logging** - Detailed console and server-side logging for debugging

## Installation

### Quick Setup (Recommended)

**Step 1: Add the dependency**

```elixir
# In mix.exs
def deps do
  [
    {:phoenix_turnstile, github: "zyzyva/phoenix_turnstile"}
  ]
end
```

**Step 2: Install dependencies**

```bash
mix deps.get
```

**Step 3: Run the installer**

```bash
mix igniter.install phoenix_turnstile
```

This automatically:
- ✅ Adds Turnstile configuration with test keys to `config/config.exs`
- ✅ Adds production environment variable configuration to `config/runtime.exs`
- ✅ Copies the JavaScript hook to `assets/js/turnstile_hook.js`
- ✅ Imports and registers the hook in your `assets/js/app.js`

**Step 4: Add the widget to your LiveView**

```elixir
def render(assigns) do
  ~H"""
  <PhoenixTurnstile.Components.widget_with_loading id="turnstile-widget" />
  """
end

def handle_event("turnstile_callback", %{"token" => _token}, socket) do
  {:noreply, socket}
end
```

**That's it!** The widget works immediately on localhost without any API keys.

For production, set environment variables:

```bash
export TURNSTILE_SITE_KEY="your_production_site_key"
export TURNSTILE_SECRET_KEY="your_production_secret_key"
```

Get your keys from: https://dash.cloudflare.com/

## Configuration

### Automatic Configuration

The installer sets up a two-tier configuration strategy:

**Development & Test (`config/config.exs`):**
```elixir
# Cloudflare test keys - work on localhost without configuration
config :phoenix_turnstile,
  site_key: "1x00000000000000000000AA",
  secret_key: "1x0000000000000000000000000000000AA"
```

**Production (`config/runtime.exs`):**
```elixir
if config_env() == :prod do
  config :phoenix_turnstile,
    site_key: System.get_env("TURNSTILE_SITE_KEY"),
    secret_key: System.get_env("TURNSTILE_SECRET_KEY")
end
```

### Why This Approach?

This configuration strategy ensures:
- ✅ **Works immediately on localhost** - test keys work on any domain without whitelisting
- ✅ **Developers can have production keys set globally** - they won't interfere with local development
- ✅ **Test environment uses test keys** - consistent test behavior, no API calls
- ✅ **Production uses real keys** - environment variables override test keys only in production

### Cloudflare Test Keys

The test keys (`1x00000000000000000000AA`) are official Cloudflare test keys that:
- Work on any domain (localhost, staging, etc.)
- Don't require domain whitelisting in Cloudflare dashboard
- Are perfect for development and testing
- Always return successful verifications

### Production Setup

For production, set your environment variables:

```bash
export TURNSTILE_SITE_KEY="your_production_site_key"
export TURNSTILE_SECRET_KEY="your_production_secret_key"
```

These will automatically override the test keys **only in production** (when `MIX_ENV=prod`).

## Usage

### Basic LiveView Integration

**1. Add the component to your LiveView template:**

```heex
<PhoenixTurnstile.Components.widget id="turnstile-widget" />
```

**2. Handle the callback in your LiveView:**

```elixir
defmodule MyAppWeb.ContactLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:turnstile_verified, false)
     |> assign(:turnstile_token, nil)}
  end

  def handle_event("turnstile_callback", %{"token" => token}, socket) do
    case PhoenixTurnstile.verify_token(token) do
      {:ok, true} ->
        {:noreply, assign(socket, :turnstile_verified, true, :turnstile_token, token)}

      _ ->
        # Verification failed but we still allow processing
        {:noreply, assign(socket, :turnstile_verified, false)}
    end
  end

  def handle_event("submit_form", params, socket) do
    # Optionally check if verified
    if socket.assigns.turnstile_verified do
      # Process form
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "Please complete verification")}
    end
  end
end
```

### Widget with Loading Indicator

```heex
<PhoenixTurnstile.Components.widget_with_loading
  id="turnstile"
  loading_text="Verifying you're human..."
  class="flex justify-center my-4"
/>
```

### Conditional Rendering

Only show the widget when Turnstile is enabled:

```heex
<div :if={PhoenixTurnstile.enabled?()}>
  <PhoenixTurnstile.Components.widget id="turnstile" />
</div>
```

### Manual Widget Reset

Reset the widget after form submission:

```elixir
def handle_event("submit_form", _params, socket) do
  # Process form...

  {:noreply,
   socket
   |> push_event("reset_turnstile", %{})
   |> assign(:turnstile_verified, false)}
end
```

## Content Security Policy (CSP)

The installer automatically updates your CSP headers to allow these Turnstile domains:

```elixir
plug :put_secure_browser_headers, %{
  "content-security-policy" =>
    "default-src 'self'; " <>
    "script-src 'self' 'unsafe-inline' https://challenges.cloudflare.com https://*.cloudflare.com; " <>
    "frame-src 'self' https://challenges.cloudflare.com https://*.cloudflare.com; " <>
    "style-src 'self' 'unsafe-inline' https://challenges.cloudflare.com; " <>
    "connect-src 'self' https://challenges.cloudflare.com https://*.cloudflare.com; " <>
    "child-src 'self' https://challenges.cloudflare.com https://*.cloudflare.com;"
}
```

If the installer cannot automatically update your CSP, you'll receive a warning with manual instructions.

## Architecture

### Graceful Failure Philosophy

PhoenixTurnstile is designed to **never block users**, even when things go wrong:

- **No API keys?** → Bypasses verification (development mode)
- **API unreachable?** → Logs warning, allows processing
- **Token verification fails?** → Logs warning, allows processing
- **JavaScript errors?** → Sends bypass token
- **Widget won't load?** → Sends bypass token

This ensures legitimate users are never frustrated by CAPTCHA issues while still providing bot protection when everything works correctly.

### Component Architecture

1. **Backend Verification** (`PhoenixTurnstile.Verification`)
   - Token verification via Cloudflare API
   - Graceful failure handling
   - Bypass token support

2. **Phoenix Components** (`PhoenixTurnstile.Components`)
   - `widget/1` - Basic Turnstile widget
   - `widget_with_loading/1` - Widget with loading indicator

3. **JavaScript Hook** (`TurnstileHook`)
   - Automatic script loading
   - Widget lifecycle management
   - Bypass token generation on errors
   - Console logging for debugging

## Testing

### Running Tests

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover
```

### Testing in Your Application

When testing forms with Turnstile in your application:

**Option 1: Use bypass tokens (recommended)**

```elixir
test "processes form with bypass token", %{conn: conn} do
  # Bypass tokens are always accepted
  socket
  |> form("#contact-form", %{token: "bypass-test"})
  |> render_submit()
end
```

**Option 2: Mock the verification**

```elixir
import Mox

# Define a mock in test/support/mocks.ex
Mox.defmock(PhoenixTurnstile.VerificationMock, for: PhoenixTurnstile.VerificationBehaviour)

# In your test
PhoenixTurnstile.VerificationMock
|> expect(:verify_token, fn _token -> {:ok, true} end)
```

## API Reference

### PhoenixTurnstile

Main module with convenience functions.

```elixir
PhoenixTurnstile.enabled?() :: boolean()
PhoenixTurnstile.site_key() :: String.t() | nil
PhoenixTurnstile.verify_token(token) :: {:ok, boolean()} | {:error, String.t()}
```

### PhoenixTurnstile.Verification

Backend token verification.

```elixir
verify_token(token) :: {:ok, boolean()} | {:error, String.t()}
enabled?() :: boolean()
site_key() :: String.t() | nil
```

### PhoenixTurnstile.Components

Phoenix LiveView components.

```elixir
widget(assigns) :: Phoenix.LiveView.Rendered.t()
widget_with_loading(assigns) :: Phoenix.LiveView.Rendered.t()
```

## Troubleshooting

### Widget not appearing or "render is not a function" error

**Problem:** Widget doesn't render or console shows `window.turnstile.render is not a function`

**Cause:** You're using `id="turnstile"` which creates a global `window.turnstile` variable that overwrites the Cloudflare Turnstile API.

**Solution:** Use a different ID:
```elixir
# ❌ BAD - causes naming collision
<PhoenixTurnstile.Components.widget id="turnstile" />

# ✅ GOOD - no collision
<PhoenixTurnstile.Components.widget id="turnstile-widget" />
<PhoenixTurnstile.Components.widget id="my-turnstile" />
```

### Widget not appearing (general)

1. Check browser console for JavaScript errors
2. Verify CSP headers allow Turnstile domains
3. Ensure `data-sitekey` attribute is set correctly
4. **Make sure you're not using `id="turnstile"`** (see above)

### Verification always fails

1. Check that `TURNSTILE_SECRET_KEY` is set
2. Verify the secret key matches your site key (sandbox vs production)
3. Check server logs for API errors
4. Ensure your server can reach `challenges.cloudflare.com`

### CSP violations

If you see CSP errors in the browser console:

1. Check that the installer updated your router correctly
2. Manually add Turnstile domains to your CSP if needed
3. Look in your router for `plug :put_secure_browser_headers`

### Development mode not working

Turnstile automatically uses bypass mode in development when keys aren't configured. If you want to test with real keys:

```bash
export USE_PROD_TURNSTILE=true
export TURNSTILE_SITE_KEY="your_sandbox_key"
export TURNSTILE_SECRET_KEY="your_sandbox_secret"
```

## Cloudflare Dashboard

- **Dashboard**: https://dash.cloudflare.com/
- **Turnstile Setup**: https://dash.cloudflare.com/?to=/:account/turnstile
- **Documentation**: https://developers.cloudflare.com/turnstile/

## Security Considerations

### When to Use Turnstile

Turnstile is ideal for:
- Public forms (contact, registration, etc.)
- API endpoints that need rate limiting
- Comment sections and user-generated content
- Password reset flows

### When NOT to Use Turnstile

Don't rely solely on Turnstile for:
- Financial transactions (use additional fraud detection)
- Administrative actions (use proper authentication/authorization)
- Critical security decisions (use defense-in-depth)

### Best Practices

1. **Always verify server-side** - Never trust client-side verification alone
2. **Use HTTPS** - Turnstile requires HTTPS in production
3. **Monitor logs** - Watch for unusual bypass rates
4. **Rate limiting** - Combine with rate limiting for API endpoints
5. **Graceful degradation** - Follow this library's approach of never blocking users

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Run `mix format` and `mix test`
5. Submit a pull request

## License

MIT

## Credits

Built by the Zyzyva Team, inspired by the Turnstile integration patterns in the contacts4us project.
