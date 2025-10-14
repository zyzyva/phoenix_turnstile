# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Automatic configuration with Cloudflare test keys for immediate localhost development
- Two-tier configuration strategy (test keys in config.exs, env vars in runtime.exs prod block)
- Dynamic `container_id` support - hook reads from data attribute instead of hardcoded value
- **Automatic hooks registration** - installer now intelligently adds hooks to LiveSocket (no manual step!)
- Comprehensive documentation warning about `id="turnstile"` naming collision
- Better error message when render method not found (hints at ID naming issue)
- QUICKSTART.md for fast onboarding

### Changed
- **IMPORTANT**: Installer now puts hardcoded test keys in config.exs instead of env var references
- Installer now adds production env var config to `if config_env() == :prod do` block in runtime.exs
- All documentation examples now use `id="turnstile-widget"` instead of `id="turnstile"`
- Components module updated with warnings about avoiding `id="turnstile"`

### Fixed
- Fixed naming collision issue where `id="turnstile"` overwrites window.turnstile API
- Fixed issue where production environment variables would be used in development
- Fixed container_id being hardcoded - now reads from `data-container-id` attribute
- Fixed installer regex to handle variations in whitespace for prod block detection
- Fixed hooks registration to work whether hooks object exists or not (handles 3 cases gracefully)

### Documentation
- Added comprehensive "Avoid id='turnstile'" warnings throughout
- Updated all code examples to use safe IDs
- Added troubleshooting section for naming collision issue
- Documented Cloudflare test keys and why they're used
- Explained configuration strategy and its benefits
- **Removed manual hooks registration step** - installer now does this automatically

## [0.1.0] - 2025-01-XX

### Added

- Initial release of PhoenixTurnstile
- Backend token verification with graceful failure handling
- Phoenix LiveView components (`widget` and `widget_with_loading`)
- JavaScript LiveView hook with automatic fallbacks
- Igniter-based installer for automatic setup
- Automatic CSP header configuration
- Development mode with bypass tokens
- Comprehensive test suite
- Full documentation and usage examples

### Features

- Graceful failure handling that never blocks users
- Zero-config development mode
- Automatic Cloudflare script loading
- Widget lifecycle management
- Console logging for debugging
- Bypass token support for testing

### Security

- Server-side token verification
- CSP-compliant implementation
- HTTPS enforcement in production
- No client-side security decisions

[0.1.0]: https://github.com/zyzyva/phoenix_turnstile/releases/tag/v0.1.0
