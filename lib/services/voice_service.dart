// lib/services/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isInitialized = false;
  static bool _isListening = false;

  /// Initialize speech recognition with detailed debugging
  static Future<bool> initialize() async {
    print('🎤 VoiceService.initialize() called');

    if (_isInitialized) {
      print('🎤 Already initialized, returning true');
      return true;
    }

    try {
      print('🎤 Requesting microphone permission...');

      // Check current permission status
      final currentStatus = await Permission.microphone.status;
      print('🎤 Current permission status: $currentStatus');

      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();
      print('🎤 Permission request result: $permissionStatus');

      if (!permissionStatus.isGranted) {
        print('🎤 Microphone permission denied');
        throw VoiceServiceException('Microphone permission denied');
      }

      print('🎤 Initializing speech-to-text...');

      // Initialize speech to text with better error handling
      _isInitialized = await _speech.initialize(
        onError: (error) {
          print(
              '🎤 Speech recognition error during operation: ${error.errorMsg}');
          // Only throw if it's a critical error, not "no match" during initialization
          if (error.errorMsg != 'error_no_match' &&
              error.errorMsg != 'error_speech_timeout') {
            throw VoiceServiceException(
              'Speech recognition error: ${error.errorMsg}',
            );
          }
        },
        onStatus: (status) {
          print('🎤 Status changed: $status');
          _isListening = status == 'listening';
        },
      );

      print('🎤 Speech initialization result: $_isInitialized');

      if (_isInitialized) {
        // Test if locales are available
        try {
          final locales = await _speech.locales();
          print('🎤 Available locales: ${locales.length}');
        } catch (e) {
          print('🎤 Could not get locales, but initialization successful: $e');
        }
      }

      return _isInitialized;
    } catch (e) {
      print('🎤 Initialize failed with error: $e');
      // If it's just a "no match" error during init, we can still proceed
      if (e.toString().contains('error_no_match') ||
          e.toString().contains('error_speech_timeout')) {
        print('🎤 Ignoring initialization test error, marking as available');
        _isInitialized = true;
        return true;
      }
      throw VoiceServiceException(
        'Failed to initialize voice service: ${e.toString()}',
      );
    }
  }

  /// Check if speech recognition is available
  static Future<bool> isAvailable() async {
    print('🎤 VoiceService.isAvailable() called');

    try {
      await initialize();
      final available = _speech.isAvailable;
      print('🎤 Speech isAvailable: $available');

      if (available) {
        // Additional checks
        try {
          final locales = await _speech.locales();
          print('🎤 Available locales count: ${locales.length}');
          return locales.isNotEmpty;
        } catch (e) {
          print('🎤 Could not get locales but speech is available: $e');
          return true; // Still consider it available
        }
      }

      return available;
    } catch (e) {
      print('🎤 isAvailable failed: $e');
      // Check if it's just initialization test errors
      if (e.toString().contains('error_no_match') ||
          e.toString().contains('error_speech_timeout') ||
          e.toString().contains(
              'VoiceServiceException: Speech recognition error: error_no_match')) {
        print('🎤 Ignoring test error, checking basic availability');
        return _speech.isAvailable;
      }
      return false;
    }
  }

  /// Check if currently listening
  static bool get isListening {
    print('🎤 isListening called, returning: $_isListening');
    return _isListening;
  }

  /// Start listening for speech input
  static Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    String localeId = 'en_US',
    bool partialResults = false,
  }) async {
    print('🎤 startListening called');

    try {
      if (!_isInitialized) {
        print('🎤 Not initialized, initializing now...');
        final initialized = await initialize();
        if (!initialized) {
          throw VoiceServiceException('Voice service not available');
        }
      }

      // Always stop any existing listening session first
      if (_isListening) {
        print('🎤 Already listening, stopping first...');
        await _speech.stop();
        await Future.delayed(Duration(milliseconds: 100));
      }

      print('🎤 Starting to listen...');
      await _speech.listen(
        onResult: (result) {
          print(
              '🎤 Speech result: ${result.recognizedWords} (final: ${result.finalResult})');
          // Only process final results to avoid duplication
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: Duration(seconds: 8), // Good duration for search queries
        pauseFor: Duration(seconds: 2), // Detect when user stops speaking
        partialResults: partialResults,
        localeId: localeId,
        onSoundLevelChange: (level) {
          // Optional: log sound levels for debugging
          // print('🎤 Sound level: $level');
        },
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      print('🎤 Listen command sent successfully');
    } catch (e) {
      print('🎤 startListening failed: $e');
      onError('Failed to start listening: ${e.toString()}');
    }
  }

  /// Stop listening
  static Future<void> stopListening() async {
    print('🎤 stopListening called');
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        await Future.delayed(Duration(milliseconds: 100));
        print('🎤 Stopped listening successfully');
      } else {
        print('🎤 Was not listening, nothing to stop');
      }
    } catch (e) {
      print('🎤 stopListening error: $e');
      _isListening = false;
    }
  }

  /// Cancel listening
  static Future<void> cancelListening() async {
    print('🎤 cancelListening called');
    try {
      if (_isListening) {
        await _speech.cancel();
        _isListening = false;
        await Future.delayed(Duration(milliseconds: 100));
        print('🎤 Cancelled listening successfully');
      }
    } catch (e) {
      print('🎤 cancelListening error: $e');
      _isListening = false;
    }
  }

  /// Get available locales for speech recognition
  static Future<List<stt.LocaleName>> getAvailableLocales() async {
    print('🎤 getAvailableLocales called');
    try {
      await initialize();
      final locales = await _speech.locales();
      print('🎤 Found ${locales.length} locales');
      for (var locale in locales) {
        print('🎤 Locale: ${locale.localeId} - ${locale.name}');
      }
      return locales;
    } catch (e) {
      print('🎤 getAvailableLocales failed: $e');
      return [];
    }
  }

  /// Check microphone permission status
  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    print('🎤 Microphone permission status: $status');
    return status.isGranted;
  }

  /// Request microphone permission with better handling
  static Future<bool> requestMicrophonePermission() async {
    print('🎤 Requesting microphone permission...');

    final status = await Permission.microphone.request();
    print('🎤 Permission request result: $status');

    // Check if permanently denied
    if (status.isPermanentlyDenied) {
      print('🎤 Permission permanently denied, need to open settings');
      return false;
    }

    return status.isGranted;
  }

  /// Check if we need to show settings dialog
  static Future<bool> isPermissionPermanentlyDenied() async {
    final status = await Permission.microphone.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings (for permanently denied permissions)
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Dispose resources (call when app is disposed)
  static Future<void> dispose() async {
    print('🎤 dispose called');
    try {
      await stopListening();
    } catch (e) {
      print('🎤 dispose error: $e');
    }
  }
}

/// Custom exception for voice service errors
class VoiceServiceException implements Exception {
  final String message;

  const VoiceServiceException(this.message);

  @override
  String toString() => 'VoiceServiceException: $message';
}
