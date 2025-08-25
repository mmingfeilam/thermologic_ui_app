import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/search_highlighter_service.dart';

// Re-enable voice service
import '../services/voice_service.dart' as voice;

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode(); // Add focus node for keyboard control

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String? _lastQuery;
  int _resultLimit = 10;

  // Search mode state variables - simplified for users
  String _searchMode = 'smart'; // Default to smart search (hybrid + reranking)
  bool _allowGlobal = false;
  bool _showAdvancedOptions = false; // Collapsible advanced options

  // Voice-to-text state variables
  bool _isListening = false;
  bool _voiceAvailable = false;
  String _voiceError = '';

  // User-friendly search modes
  final Map<String, Map<String, dynamic>> _searchModes = {
    'smart': {
      'name': 'Smart Search',
      'description': 'Best results using AI + keyword matching',
      'icon': Icons.auto_awesome,
      'color': Colors.blue,
      'use_hybrid': true,
      'use_reranking': true,
      'technical': 'hybrid + reranking',
    },
    'concept': {
      'name': 'Concept Search',
      'description': 'Find ideas and meanings, not exact words',
      'icon': Icons.psychology,
      'color': Colors.green,
      'use_hybrid': false,
      'use_reranking': true,
      'technical': 'vector + reranking',
    },
    'fast': {
      'name': 'Fast Search',
      'description': 'Quick results with good accuracy',
      'icon': Icons.speed,
      'color': Colors.orange,
      'use_hybrid': true,
      'use_reranking': false,
      'technical': 'hybrid only',
    },
    'basic': {
      'name': 'Basic Search',
      'description': 'Fastest, finds similar content only',
      'icon': Icons.search,
      'color': Colors.purple,
      'use_hybrid': false,
      'use_reranking': false,
      'technical': 'vector only',
    },
  };

  // Helper getters
  String get _currentSearchModeName => _searchModes[_searchMode]!['name'];
  String get _currentSearchModeDescription =>
      _searchModes[_searchMode]!['description'];
  Color get _currentSearchModeColor => _searchModes[_searchMode]!['color'];
  IconData get _currentSearchModeIcon => _searchModes[_searchMode]!['icon'];
  bool get _useHybrid => _searchModes[_searchMode]!['use_hybrid'];
  bool get _enableReranking => _searchModes[_searchMode]!['use_reranking'];

  // Predefined search suggestions for industrial refrigeration
  final List<String> _searchSuggestions = [
    'temperature sensor malfunction',
    'compressor maintenance schedule',
    'refrigerant leak detection',
    'evaporator coil cleaning',
    'condenser fan motor',
    'thermostat calibration',
    'pressure switch adjustment',
    'defrost cycle problems',
    'electrical wiring diagrams',
    'safety procedures',
  ];

  @override
  void initState() {
    super.initState();
    // Re-enable voice availability check
    _checkVoiceAvailability();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    // Re-enable voice cleanup
    voice.VoiceService.dispose();
    super.dispose();
  }

  // Re-enable voice availability check
  Future<void> _checkVoiceAvailability() async {
    try {
      print('🎤 Checking voice availability...');
      print('🎤 About to call voice.VoiceService.isAvailable()');

      final available = await voice.VoiceService.isAvailable();
      print('🎤 Voice available: $available');

      if (mounted) {
        setState(() {
          _voiceAvailable = available;
        });
      }

      if (available) {
        print('🎤 Voice service initialized successfully');
      } else {
        print('🎤 Voice service not available');
        // Let's try to get more debug info
        print('🎤 Attempting manual permission check...');
        final hasPermission =
            await voice.VoiceService.hasMicrophonePermission();
        print('🎤 Current microphone permission: $hasPermission');

        if (!hasPermission) {
          print('🎤 Requesting microphone permission manually...');
          final granted =
              await voice.VoiceService.requestMicrophonePermission();
          print('🎤 Permission request result: $granted');
        }
      }
    } catch (e, stackTrace) {
      print('🎤 Voice not available - Error: $e');
      print('🎤 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _voiceAvailable = false;
          _voiceError = 'Voice service error: ${e.toString()}';
        });
      }
    }
  }

  // Method to dismiss keyboard
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // Start voice input with better permission handling
  Future<void> _startVoiceInput() async {
    try {
      // Check if permission is permanently denied first
      final isPermanentlyDenied =
          await voice.VoiceService.isPermissionPermanentlyDenied();
      if (isPermanentlyDenied) {
        _showPermissionDialog();
        return;
      }

      setState(() {
        _isListening = true;
        _voiceError = '';
      });

      _dismissKeyboard(); // Hide keyboard when starting voice input

      await voice.VoiceService.startListening(
        onResult: (recognizedWords) {
          // Update search field with recognized text
          setState(() {
            _searchController.text = recognizedWords.trim();
            _isListening = false;
          });

          // Auto-search if we got results
          if (recognizedWords.trim().isNotEmpty) {
            _performSearch();
          }
        },
        onError: (error) {
          setState(() {
            _isListening = false;
            _voiceError = error;
          });

          // Clear error after a few seconds
          Future.delayed(Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _voiceError = '';
              });
            }
          });
        },
        partialResults: false, // Only get final results
      );
    } catch (e) {
      setState(() {
        _isListening = false;
        _voiceError = 'Voice input failed: ${e.toString()}';
      });

      // Clear error after a few seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _voiceError = '';
          });
        }
      });
    }
  }

  // Show permission dialog for permanently denied permissions
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Microphone Permission Required"),
        content: Text(
            "Please enable microphone access in Settings > ThermoLogic to use voice search."),
        actions: [
          TextButton(
            child: Text("Open Settings"),
            onPressed: () {
              voice.VoiceService.openAppSettings();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // Re-enable stop voice input
  Future<void> _stopVoiceInput() async {
    await voice.VoiceService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap anywhere to dismiss keyboard
      onTap: _dismissKeyboard,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Header
              Row(
                children: [
                  Text(
                    'Search Manuals',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          fontSize: 18,
                        ),
                  ),
                  Spacer(),
                  // Advanced options toggle
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                      _dismissKeyboard();
                    },
                    icon: Icon(
                      _showAdvancedOptions ? Icons.expand_less : Icons.tune,
                      color: Color(0xFF1E3A8A),
                    ),
                    tooltip: 'Options',
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Compact Search Input
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      // Search TextField - more compact
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: 'Search documents...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              onSubmitted: (value) {
                                _performSearch();
                                _dismissKeyboard();
                              },
                              onChanged: (_) => setState(() {}),
                              textInputAction: TextInputAction.search,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Quick action buttons
                          Column(
                            children: [
                              // Voice button
                              if (_voiceAvailable)
                                Container(
                                  width: 36,
                                  height: 36,
                                  child: IconButton(
                                    onPressed: _isListening
                                        ? _stopVoiceInput
                                        : _startVoiceInput,
                                    icon: Icon(
                                      _isListening ? Icons.stop : Icons.mic,
                                      size: 18,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _isListening
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                      foregroundColor: _isListening
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 4),
                              // Clear button
                              if (_searchController.text.isNotEmpty)
                                Container(
                                  width: 36,
                                  height: 36,
                                  child: IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _lastQuery = null;
                                      });
                                    },
                                    icon: Icon(Icons.clear, size: 18),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey.shade100,
                                      foregroundColor: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Search mode selection + Search Button Row
                      Row(
                        children: [
                          // Search mode selector - user-friendly
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Current mode indicator
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _currentSearchModeColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: _currentSearchModeColor
                                            .withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_currentSearchModeIcon,
                                          size: 12,
                                          color: _currentSearchModeColor),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _currentSearchModeName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _currentSearchModeColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '(H=${_useHybrid ? 'T' : 'F'} R=${_enableReranking ? 'T' : 'F'})',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.grey[600],
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 4),
                                // Mode selector dropdown
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _searchMode,
                                      isDense: true,
                                      isExpanded: true,
                                      items: _searchModes.entries.map((entry) {
                                        final mode = entry.value;
                                        return DropdownMenuItem(
                                          value: entry.key,
                                          child: Row(
                                            children: [
                                              Icon(mode['icon'],
                                                  size: 14,
                                                  color: mode['color']),
                                              SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  mode['name'],
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _searchMode = value!;
                                        });
                                        _dismissKeyboard();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          // Search button - compact
                          ElevatedButton(
                            onPressed:
                                _searchController.text.trim().isNotEmpty &&
                                        !_isSearching
                                    ? () {
                                        _performSearch();
                                        _dismissKeyboard();
                                      }
                                    : null,
                            child: _isSearching
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(Icons.search, size: 18),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(44, 32),
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),

                      // Advanced Options - Collapsible
                      if (_showAdvancedOptions) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.settings,
                                      size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    'Advanced Options',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  // Global search toggle
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: _allowGlobal,
                                          onChanged: (value) {
                                            setState(() {
                                              _allowGlobal = value ?? false;
                                            });
                                            _dismissKeyboard();
                                          },
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Text(
                                          'Global Search',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Result limit
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: _resultLimit,
                                        isDense: true,
                                        items: [5, 10, 20, 50].map((limit) {
                                          return DropdownMenuItem(
                                            value: limit,
                                            child: Text(
                                              '$limit',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _resultLimit = value!;
                                          });
                                          _dismissKeyboard();
                                          // Auto-search if there's already a query
                                          if (_lastQuery != null &&
                                              _lastQuery!.isNotEmpty) {
                                            _performSearch();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Search mode explanations with technical details
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Search Modes Explained:',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    ..._searchModes.entries.map((entry) {
                                      final mode = entry.value;
                                      final isActive = _searchMode == entry.key;
                                      return Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 1),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? mode['color']
                                                    : Colors.grey.shade300,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: isActive
                                                        ? mode['color']
                                                        : Colors.grey[600],
                                                    fontWeight: isActive
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: '${mode['name']}: ',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                    TextSpan(
                                                        text: mode[
                                                            'description']),
                                                    TextSpan(
                                                      text:
                                                          ' (${mode['technical']})',
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Voice status indicator - only if active
                      if (_voiceAvailable &&
                          (_isListening || _voiceError.isNotEmpty)) ...[
                        SizedBox(height: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.red.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _isListening
                                  ? Colors.red.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isListening ? Icons.mic : Icons.error_outline,
                                color: _isListening ? Colors.red : Colors.red,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _isListening ? 'Listening...' : _voiceError,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                              if (_isListening)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 8),

              // Results Section - Takes remaining space
              Expanded(
                child: _buildResultsSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_searchResults.isEmpty && !_isSearching && _lastQuery == null) {
      return _buildEmptyState();
    }

    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty && _lastQuery != null) {
      return _buildNoResultsState();
    }

    return _buildSearchResults();
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Quick Search Suggestions - More compact
          Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Color(0xFF1E3A8A), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Quick Search',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _searchSuggestions.take(6).map((suggestion) {
                      return ActionChip(
                        label: Text(
                          suggestion,
                          style: TextStyle(fontSize: 10),
                        ),
                        onPressed: () {
                          _searchController.text = suggestion;
                          _performSearch();
                          _dismissKeyboard();
                        },
                        backgroundColor: Color(0xFF1E3A8A).withOpacity(0.1),
                        labelStyle: TextStyle(color: Color(0xFF1E3A8A)),
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12),

          // Search Tips - Compact
          Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF1E3A8A), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Search Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...[
                    'Use specific terms like "temperature sensor"',
                    'Search symptoms: "not cooling properly"',
                    'Include model numbers when known',
                    'Try different search mode combinations for better results'
                  ]
                      .map((tip) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 1),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ',
                                    style: TextStyle(
                                        color: Color(0xFF1E3A8A),
                                        fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Searching documents...',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Using $_currentSearchModeName',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'for "$_lastQuery"',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'using $_currentSearchModeName',
              style: TextStyle(
                color: _currentSearchModeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Try:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text('• Different keywords or phrases',
                    style: TextStyle(fontSize: 14)),
                Text('• More general terms', style: TextStyle(fontSize: 14)),
                Text('• Checking spelling', style: TextStyle(fontSize: 14)),
                Text('• Try a different search mode',
                    style: TextStyle(fontSize: 14)),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                  _lastQuery = null;
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('New Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Results Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Icon(
                _currentSearchModeIcon,
                size: 14,
                color: _currentSearchModeColor,
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '"$_lastQuery"',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_searchResults.length} results • ${_currentSearchModeName} (H=${_useHybrid ? 'T' : 'F'} R=${_enableReranking ? 'T' : 'F'})',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // Results List - Takes remaining space
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _buildResultCard(result, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result, int index) {
    final similarity = (result['score'] is String)
        ? double.tryParse(result['score']) ?? 0.0
        : result['score']?.toDouble() ?? 0.0;

    final relevanceColor = _getRelevanceColor(similarity);
    final content = result['content'] ?? 'No content available';
    final documentName = result['document_name'] ?? 'Unknown Document';

    // Extract query terms and create smart snippet using SearchHighlighterService
    final queryTerms =
        SearchHighlighterService.extractQueryTerms(_lastQuery ?? '');
    final smartSnippet = SearchHighlighterService.extractSmartSnippet(
      content,
      queryTerms,
      maxLength: 150,
    );

    // Get match statistics
    final matchStats =
        SearchHighlighterService.getMatchStats(content, queryTerms);

    return Card(
      margin: EdgeInsets.only(bottom: 6),
      elevation: 2,
      child: InkWell(
        onTap: () => _showFullContent(result),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with highlighted document name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: SearchHighlighterService.highlightText(
                        documentName,
                        queryTerms,
                        theme: 'subtle',
                        baseStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  _buildRelevanceChip(similarity, relevanceColor),
                ],
              ),

              // Metadata row
              if (result['page_number'] != null ||
                  matchStats['totalMatches'] > 0) ...[
                SizedBox(height: 4),
                _buildMetadataRow(result, matchStats),
              ],

              SizedBox(height: 6),

              // Highlighted content snippet
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: RichText(
                  text: SearchHighlighterService.highlightText(
                    smartSnippet,
                    queryTerms,
                    theme: 'default',
                    baseStyle: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: Colors.grey[800],
                    ),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: 6),

              // Action row
              _buildActionRow(result, matchStats),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for relevance chip
  Widget _buildRelevanceChip(double similarity, Color relevanceColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: relevanceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: relevanceColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 10, color: relevanceColor),
          SizedBox(width: 2),
          Text(
            '${(similarity * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: relevanceColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for metadata row
  Widget _buildMetadataRow(
      Map<String, dynamic> result, Map<String, dynamic> matchStats) {
    return Row(
      children: [
        if (result['page_number'] != null) ...[
          Icon(Icons.description, size: 10, color: Colors.grey[600]),
          SizedBox(width: 2),
          Text(
            'Page ${result['page_number']}',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ],
        if (result['page_number'] != null && matchStats['totalMatches'] > 0)
          Text(' • ', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        if (matchStats['totalMatches'] > 0) ...[
          Icon(Icons.search, size: 10, color: Colors.blue[600]),
          SizedBox(width: 2),
          Text(
            '${matchStats['totalMatches']} match${matchStats['totalMatches'] > 1 ? 'es' : ''}',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  // Helper method for action row
  Widget _buildActionRow(
      Map<String, dynamic> result, Map<String, dynamic> matchStats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Match indicator chip
        if (matchStats['matchedTerms'].length > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              '${matchStats['matchedTerms'].length}/${SearchHighlighterService.extractQueryTerms(_lastQuery ?? '').length} terms',
              style: TextStyle(
                fontSize: 9,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => _showFullContent(result),
              icon: Icon(Icons.visibility, size: 12),
              label: Text('View', style: TextStyle(fontSize: 10)),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF1E3A8A),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size(0, 28),
              ),
            ),
            TextButton.icon(
              onPressed: () => _copyContent(result['content'] ?? ''),
              icon: Icon(Icons.copy, size: 12),
              label: Text('Copy', style: TextStyle(fontSize: 10)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size(0, 28),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Enhanced full content dialog
  void _showFullContent(Map<String, dynamic> result) {
    final queryTerms =
        SearchHighlighterService.extractQueryTerms(_lastQuery ?? '');
    final content = result['content'] ?? 'No content available';
    final documentName = result['document_name'] ?? 'Document Content';
    final matchStats =
        SearchHighlighterService.getMatchStats(content, queryTerms);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(documentName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced metadata section
                _buildFullContentMetadata(result, matchStats),
                SizedBox(height: 12),

                // Full content with highlighting - using fallback if highlighting fails
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: queryTerms.isNotEmpty
                      ? SelectableText.rich(
                          _buildHighlightedTextSpan(content, queryTerms),
                        )
                      : SelectableText(
                          content,
                          style: TextStyle(height: 1.4, fontSize: 13),
                        ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _copyContent(content),
            icon: Icon(Icons.copy, size: 16),
            label: Text('Copy All'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, size: 16),
            label: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Fallback highlighting method to ensure content is always shown
  TextSpan _buildHighlightedTextSpan(String content, List<String> queryTerms) {
    try {
      return SearchHighlighterService.highlightText(
        content,
        queryTerms,
        theme: 'default',
        baseStyle: TextStyle(height: 1.4, fontSize: 13),
      );
    } catch (e) {
      // Fallback to simple highlighting if service fails
      return _simpleHighlight(content, queryTerms);
    }
  }

  // Simple fallback highlighting
  TextSpan _simpleHighlight(String content, List<String> queryTerms) {
    if (queryTerms.isEmpty || content.isEmpty) {
      return TextSpan(
          text: content, style: TextStyle(height: 1.4, fontSize: 13));
    }

    List<TextSpan> spans = [];
    String remainingContent = content;
    int currentIndex = 0;

    // Create simple regex for highlighting
    String pattern = queryTerms.map((term) => RegExp.escape(term)).join('|');
    RegExp regex = RegExp('($pattern)', caseSensitive: false);

    for (Match match in regex.allMatches(content)) {
      // Add text before the match
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: content.substring(currentIndex, match.start),
          style: TextStyle(height: 1.4, fontSize: 13),
        ));
      }

      // Add the highlighted match
      spans.add(TextSpan(
        text: match.group(0)!,
        style: TextStyle(
          backgroundColor: Colors.yellow.shade200,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          height: 1.4,
          fontSize: 13,
        ),
      ));

      currentIndex = match.end;
    }

    // Add remaining text after the last match
    if (currentIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(currentIndex),
        style: TextStyle(height: 1.4, fontSize: 13),
      ));
    }

    return TextSpan(children: spans);
  }

  // Helper for full content metadata
  Widget _buildFullContentMetadata(
      Map<String, dynamic> result, Map<String, dynamic> matchStats) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          if (result['page_number'] != null) ...[
            Icon(Icons.description, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              'Page ${result['page_number']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(' • ', style: TextStyle(color: Colors.grey[400])),
          ],
          Icon(Icons.highlight_alt, size: 16, color: Colors.blue[600]),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              '${matchStats['totalMatches']} matches found in ${matchStats['matchedTerms'].length} different terms',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRelevanceColor(double similarity) {
    if (similarity >= 0.8) return Colors.green;
    if (similarity >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getRelevanceText(double similarity) {
    if (similarity >= 0.8) return 'High Relevance';
    if (similarity >= 0.6) return 'Medium Relevance';
    return 'Low Relevance';
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
      _lastQuery = query;
    });

    try {
      print('🔍 SEARCH API CALL:');
      print('   Query: "$query"');
      print('   use_hybrid: $_useHybrid');
      print('   use_reranking: $_enableReranking');
      print('   allow_global: $_allowGlobal');
      print('   limit: $_resultLimit');
      print('   Search Mode: $_currentSearchModeName');

      final result = await ApiService.searchDocuments(
        query,
        limit: _resultLimit,
        useHybrid: _useHybrid,
        enableReranking: _enableReranking,
        allowGlobal: _allowGlobal,
      );

      print('🔥 API RESPONSE:');
      print('   Success: ${result['success']}');
      if (result['success'] && result['data'] != null) {
        final results = result['data']['results'] ?? [];
        print('   Results count: ${results.length}');
        if (results.isNotEmpty) {
          print('   First result score: ${results[0]['score']}');
          print('   First result doc: ${results[0]['document_name']}');
        }
      } else {
        print('   Error: ${result['error']}');
      }

      setState(() {
        _isSearching = false;
        if (result['success']) {
          _searchResults = result['data']['results'] ?? [];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Search failed: ${result['error'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyContent(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Content copied to clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy content'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
