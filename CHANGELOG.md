# Change Log

## [5.5.0](https://github.com/tresorit/ZeroKit-iOS-SDK/releases/tag/5.5.0)
### Changes
- ZeroKit has been rewritten to use the JavaScriptCore framework to execute javascript instead of WKWebView.
- Javascript execution is now possible while the app is in the background.
- Cryptographic operations are implemented in native code providing improved performance over javascript implementations.

### Added
- New error codes.
- More descriptive error messages for developers. This includes descriptions and origin of errors.
- You can now set the log level with `ZeroKit.logLevel`. Defaults to `warning`.

## [5.0.0](https://github.com/tresorit/ZeroKit-iOS-SDK/releases/tag/5.0.0) - 2017-07-18
### Changes
- Use ZeroKit JavaScript API version 5.
- `init(apiBaseUrl: URL)` on `ZeroKitConfig` has been deprecated in favor of `init(serviceUrl: URL)`. The value for the URL parameter is the same, it has been renamed for consistency.

### Added
- Invitation links can now be revoked using the `ZeroKit.revokeInvitationLink(forTresor:secret:completion:)` instance method.

### Removed
- Removed deprecated APIs: `ZeroKit.DidFailLoadingNotification`, `ZeroKit.DidLoadNotification`, `ZeroKit.isLoaded`, `ZeroKitConfig.init(apiUrl:)`.

## [4.1.2](https://github.com/tresorit/ZeroKit-iOS-SDK/releases/tag/4.1.2) - 2017-06-26
### Added
- `clear` method to `ZeroKitPasswordField`.

### Changes
- Improved data escaping performance during encryption and decryption.

### Example App Changes
- Added support for user public profile to the `Backend` class.
- Turned off autocorrection in username text fields.

## [4.1.1](https://github.com/tresorit/ZeroKit-iOS-SDK/releases/tag/4.1.1) - 2017-04-05
### Fixed
- Identity provider redirect URL when configured ZeroKit with a service URL ending with a slash or with deprecated `apiUrl` method.

### Example App Changes
- The example app now uses our [sample backend](https://github.com/tresorit/ZeroKit-NodeJs-backend-sample). See the updated [README](README.md) for more information.

## [4.1.0](https://github.com/tresorit/ZeroKit-iOS-SDK/releases/tag/4.1.0) - 2017-03-30
### Added
- OpenID Connect identity provider support. See the `getIdentityTokens` function on `ZeroKit`.
- ZeroKit can now be configured with the api base URL (also known as the service URL), `ZeroKitConfig(apiBaseUrl: URL(string: "https://{TenantID}.api.tresorit.io")!)`

### Changes
- In version 4.1.0 you no longer have to subscribe to `ZeroKit.DidLoadNotification` or `ZeroKit.DidFailLoadingNotification` notifications. You can start making ZeroKit calls right after initialization. The SDK will load the API internally and only after that will it handle your calls. This means you can just remove your observers for these notifications.
- *Deprecated:* Due to the above changes, `ZeroKit.DidLoadNotification`, `ZeroKit.DidFailLoadingNotification` and `ZeroKit.isLoaded` have been deprecated and will be removed in a future version.
- *Deprecated:* `ZeroKitConfig(apiUrl: URL)` has been deprecated in favor of `ZeroKitConfig(apiBaseUrl: URL)` and will be removed in a future version.
- See the migration guide section in the [README](README.md) for more information on the changes.

## [4.0.3](https://github.com/tresorit/ZeroKit-iOS-SDK/releases/tag/4.0.3) - 2017-03-24
### Added
- Password strength estimation to `ZeroKit`. You can pass a `ZeroKitPasswordField` directly to `ZeroKit.passwordStrength(passwordField:completion:)`.

### Changes
- *Deprecated:* `ZeroKitPasswordField.isPasswordValid` has been deprecated and will be removed in a future version. Use the above mentioned password strength method instead.

## [4.0.2](https://github.com/tresorit/ZeroKit-iOS-SDK/releases/tag/4.0.2) - 2017-02-13
### Added
- Tests for two simultaneous ZeroKit users.

### Example App Changes
- Changed the api URL format in the example app configuration.

## [4.0.1](https://github.com/tresorit/ZeroKit-iOS-SDK/releases/tag/4.0.1) - 2017-01-20
First public release.
