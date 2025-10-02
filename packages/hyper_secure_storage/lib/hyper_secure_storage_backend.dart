/// A secure storage backend for HyperStorage using platform-native encryption.
///
/// This library provides a [SecureStorageBackend] implementation that leverages
/// platform-specific secure storage mechanisms to protect sensitive data through
/// hardware-backed encryption and operating system security features.
///
/// ## Overview
///
/// The hyper_secure_storage backend is designed for storing sensitive information
/// such as authentication tokens, API keys, user credentials, encryption keys,
/// and personally identifiable information (PII). It integrates with:
///
/// - **Android**: Android Keystore system with AES256-encrypted SharedPreferences
/// - **iOS/macOS**: Keychain Services with configurable accessibility levels
/// - **Windows**: Windows Credential Store (Credential Manager)
/// - **Linux**: Secret Service API (libsecret) / GNOME Keyring
/// - **Web**: Web Cryptography API with IndexedDB storage
///
/// ## Key Features
///
/// ### Security
/// - **Hardware-Backed Encryption**: Uses device security hardware when available
/// - **OS-Managed Keys**: Cryptographic keys are managed by the operating system
/// - **Secure Enclave**: Utilizes iOS Secure Enclave and Android Keystore TEE
/// - **Data Protection**: Automatic encryption at rest for all stored values
/// - **Secure Deletion**: Platform-native secure wiping of deleted data
///
/// ### Platform Integration
/// - **Biometric Protection**: Leverages device biometric authentication
/// - **Device Lock Integration**: Respects device lock screen security
/// - **App Sandboxing**: Data is isolated per application
/// - **System Backup**: Configurable inclusion/exclusion from system backups
///
/// ### Developer Experience
/// - **Simple API**: Familiar key-value storage interface
/// - **Type Safety**: Strongly-typed getters and setters
/// - **Async Operations**: All operations are asynchronous and non-blocking
/// - **Error Handling**: Clear exceptions for error scenarios
///
/// ## Installation
///
/// Add the package to your `pubspec.yaml`:
///
/// ```yaml
/// dependencies:
///   hyper_storage: ^latest_version
///   hyper_secure_storage: ^latest_version
///   flutter_secure_storage: ^latest_version
/// ```
///
/// ### Platform-Specific Setup
///
/// #### Android
///
/// Minimum SDK version 18 (Android 4.3) is required. For encrypted shared
/// preferences, API level 23 (Android 6.0) or higher is recommended.
///
/// No additional configuration required for basic usage.
///
/// #### iOS/macOS
///
/// Enable Keychain Sharing in Xcode if you need to share data between apps:
///
/// 1. Open your project in Xcode
/// 2. Select your target
/// 3. Go to "Signing & Capabilities"
/// 4. Add "Keychain Sharing" capability
/// 5. Add a keychain group identifier
///
/// #### Linux
///
/// Install libsecret:
///
/// ```bash
/// sudo apt-get install libsecret-1-dev
/// ```
///
/// #### Web
///
/// No additional setup required. Uses browser's built-in secure storage APIs.
///
/// ## Usage
///
/// ### Basic Usage
///
/// ```dart
/// import 'package:hyper_storage/hyper_storage.dart';
/// import 'package:hyper_secure_storage/hyper_secure_storage_backend.dart';
///
/// // Initialize the storage with secure backend
/// final storage = await HyperStorage.getInstance(
///   backend: SecureStorageBackend(),
/// );
///
/// // Store sensitive data
/// await storage.setString('auth_token', 'eyJhbGciOiJIUzI1NiIs...');
/// await storage.setInt('user_id', 12345);
/// await storage.setBool('biometric_enabled', true);
///
/// // Retrieve data
/// final token = await storage.getString('auth_token');
/// final userId = await storage.getInt('user_id');
/// final biometricEnabled = await storage.getBool('biometric_enabled');
///
/// // Remove data
/// await storage.remove('auth_token');
///
/// // Clear all data (e.g., on logout)
/// await storage.clear();
/// ```
///
/// ### Custom Configuration
///
/// ```dart
/// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
/// import 'package:hyper_secure_storage/hyper_secure_storage_backend.dart';
///
/// // High-security configuration for sensitive applications
/// final secureBackend = SecureStorageBackend(
///   storage: FlutterSecureStorage(
///     aOptions: AndroidOptions(
///       encryptedSharedPreferences: true,
///       keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
///       storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
///     ),
///     iOptions: IOSOptions(
///       accessibility: KeychainAccessibility.first_unlock_this_device_only,
///       synchronizable: false, // Don't sync to iCloud
///     ),
///   ),
/// );
///
/// final storage = await HyperStorage.getInstance(backend: secureBackend);
/// ```
///
/// ### Common Use Cases
///
/// #### Authentication Flow
///
/// ```dart
/// // Store authentication data on login
/// Future<void> saveAuthData(String token, String refreshToken, int userId) async {
///   await storage.setString('auth_token', token);
///   await storage.setString('refresh_token', refreshToken);
///   await storage.setInt('user_id', userId);
///   await storage.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
/// }
///
/// // Check if user is authenticated
/// Future<bool> isAuthenticated() async {
///   final token = await storage.getString('auth_token');
///   return token != null && token.isNotEmpty;
/// }
///
/// // Clear authentication data on logout
/// Future<void> logout() async {
///   await storage.removeAll(['auth_token', 'refresh_token', 'user_id', 'login_timestamp']);
/// }
/// ```
///
/// #### Secure Configuration Storage
///
/// ```dart
/// // Store API configuration
/// Future<void> saveApiConfig(String apiKey, String endpoint) async {
///   await storage.setString('api_key', apiKey);
///   await storage.setString('api_endpoint', endpoint);
/// }
///
/// // Retrieve API configuration
/// Future<Map<String, String>> getApiConfig() async {
///   final data = await storage.getAll(['api_key', 'api_endpoint']);
///   return {
///     'api_key': data['api_key'] as String? ?? '',
///     'api_endpoint': data['api_endpoint'] as String? ?? '',
///   };
/// }
/// ```
///
/// #### Biometric Settings
///
/// ```dart
/// // Store user's biometric preference
/// Future<void> setBiometricEnabled(bool enabled) async {
///   await storage.setBool('biometric_enabled', enabled);
///   if (!enabled) {
///     // Clear any biometric-protected data
///     await storage.remove('biometric_token');
///   }
/// }
///
/// // Check biometric setting
/// Future<bool> isBiometricEnabled() async {
///   return await storage.getBool('biometric_enabled') ?? false;
/// }
/// ```
///
/// ## Security Best Practices
///
/// ### DO
///
/// - Use secure storage for authentication tokens, API keys, and passwords
/// - Clear sensitive data from memory after use when possible
/// - Implement proper logout flows that clear all sensitive data
/// - Use appropriate keychain accessibility levels for your use case
/// - Test security configurations on physical devices
/// - Implement token refresh mechanisms for expired credentials
/// - Use biometric authentication for additional security layer
/// - Consider encrypting additional sensitive data before storage
///
/// ### DON'T
///
/// - Don't store large amounts of data (use regular storage for non-sensitive data)
/// - Don't store sensitive data in plain text elsewhere in your app
/// - Don't share secure storage keys across different security contexts
/// - Don't disable encryption features unless absolutely necessary
/// - Don't ignore platform-specific security requirements
/// - Don't assume stored data is accessible immediately after device boot
/// - Don't store secrets in source code or configuration files
///
/// ## Platform-Specific Considerations
///
/// ### Android
///
/// - **API 23+**: Uses Android Keystore with hardware-backed encryption
/// - **API 18-22**: Uses software-based encryption fallback
/// - **Device Security**: Requires device lock screen for maximum security
/// - **App Uninstall**: Data is automatically cleared on app uninstall
/// - **Backup**: Encrypted SharedPreferences are excluded from backups
///
/// ### iOS
///
/// - **Accessibility Levels**: Choose based on when data should be accessible
///   - `unlocked`: Only when device is unlocked (recommended)
///   - `first_unlock`: After first unlock since boot
///   - `always`: Even when device is locked (less secure)
/// - **Keychain Groups**: Enable sharing between apps if needed
/// - **iCloud Sync**: Configure `synchronizable` flag appropriately
/// - **App Deletion**: Keychain items may persist after app deletion
///
/// ### Web
///
/// - **Browser Support**: Requires modern browsers with Web Crypto API
/// - **Storage Limits**: Subject to browser storage quotas
/// - **Incognito Mode**: Data may not persist in private browsing
/// - **Cross-Origin**: Data is isolated per origin
///
/// ## Performance Characteristics
///
/// - **Write Operations**: ~10-50ms depending on platform and data size
/// - **Read Operations**: ~5-20ms depending on platform and encryption
/// - **Batch Operations**: Use `setAll()` and `getAll()` for better performance
/// - **Memory Usage**: Minimal, data is encrypted on disk
/// - **Storage Limits**: Platform-dependent, typically several MB
///
/// ## Error Handling
///
/// ```dart
/// try {
///   await storage.setString('secure_key', 'sensitive_value');
/// } on PlatformException catch (e) {
///   if (e.code == 'USER_CANCELED') {
///     // User canceled biometric authentication
///   } else if (e.code == 'NOT_AVAILABLE') {
///     // Secure storage not available on this device
///   } else {
///     // Handle other platform-specific errors
///   }
/// } catch (e) {
///   // Handle unexpected errors
/// }
/// ```
///
/// ## Testing
///
/// For unit testing, use a mock backend:
///
/// ```dart
/// import 'package:mockito/mockito.dart';
/// import 'package:hyper_storage/hyper_storage.dart';
///
/// class MockSecureStorage extends Mock implements StorageBackend {}
///
/// void main() {
///   test('authentication flow', () async {
///     final mockBackend = MockSecureStorage();
///     when(mockBackend.getString('auth_token'))
///         .thenAnswer((_) async => 'mock_token');
///
///     final storage = await HyperStorage.getInstance(backend: mockBackend);
///     // Test your authentication logic...
///   });
/// }
/// ```
///
/// ## Migration from Other Storage Solutions
///
/// ### From SharedPreferences
///
/// ```dart
/// // Read from old storage
/// final prefs = await SharedPreferences.getInstance();
/// final token = prefs.getString('auth_token');
///
/// // Migrate to secure storage
/// if (token != null) {
///   await storage.setString('auth_token', token);
///   await prefs.remove('auth_token'); // Clean up old storage
/// }
/// ```
///
/// ### From Hive
///
/// ```dart
/// final box = await Hive.openBox('secure');
/// final token = box.get('auth_token');
///
/// if (token != null) {
///   await storage.setString('auth_token', token);
///   await box.delete('auth_token');
/// }
/// ```
///
/// ## Troubleshooting
///
/// ### Issue: Data not persisting
/// - Check device lock screen is configured (Android)
/// - Verify app has proper permissions
/// - Check platform-specific setup requirements
///
/// ### Issue: Data inaccessible after device restart
/// - Review iOS accessibility settings
/// - Consider using `first_unlock` instead of `unlocked`
///
/// ### Issue: Performance problems
/// - Reduce storage size (avoid large values)
/// - Use batch operations where possible
/// - Consider caching frequently accessed values
///
/// ## Related Packages
///
/// - [hyper_storage](https://pub.dev/packages/hyper_storage) - Core storage framework
/// - [hyper_storage_hive](https://pub.dev/packages/hyper_storage_hive) - High-performance local storage
/// - [hyper_storage_shared_preferences](https://pub.dev/packages/hyper_storage_shared_preferences) - SharedPreferences backend
/// - [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) - Underlying secure storage library
///
/// ## API Reference
///
/// See [SecureStorageBackend] for the main class documentation.
///
/// ## Support
///
/// For issues, feature requests, and contributions, visit:
/// https://github.com/birjuvachhani/hyper_storage
library;

export 'src/backend.dart';
