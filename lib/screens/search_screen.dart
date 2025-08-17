import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

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

  // Voice-to-text state variables
  bool _isListening = false;
  bool _voiceAvailable = false;
  String _voiceError = '';

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
              Text(
                'Search Manuals',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                      fontSize: 20, // Slightly smaller for mobile
                    ),
              ),
              SizedBox(height: 12),

              // Search Input Card - More compact
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Search TextField
                      TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          labelText: 'Search query',
                          hintText: _voiceAvailable
                              ? 'e.g., "temperature control" or tap mic to speak'
                              : 'e.g., "temperature control"',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search, size: 20),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Voice input button
                              if (_voiceAvailable)
                                IconButton(
                                  icon: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none,
                                    color:
                                        _isListening ? Colors.red : Colors.blue,
                                    size: 20,
                                  ),
                                  onPressed: _isListening
                                      ? _stopVoiceInput
                                      : _startVoiceInput,
                                  tooltip: _isListening
                                      ? 'Stop listening'
                                      : 'Voice input',
                                ),
                              // Clear button
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _lastQuery = null;
                                    });
                                  },
                                ),
                              // Keyboard dismiss button
                              IconButton(
                                icon: Icon(Icons.keyboard_hide, size: 20),
                                onPressed: _dismissKeyboard,
                                tooltip: 'Hide keyboard',
                              ),
                            ],
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        onSubmitted: (value) {
                          _performSearch();
                          _dismissKeyboard();
                        },
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        style: TextStyle(fontSize: 14),
                      ),

                      // Voice status indicator
                      if (_voiceAvailable &&
                          (_isListening || _voiceError.isNotEmpty)) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.red.shade50
                                : _voiceError.isNotEmpty
                                    ? Colors.red.shade50
                                    : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isListening
                                  ? Colors.red.shade200
                                  : _voiceError.isNotEmpty
                                      ? Colors.red.shade200
                                      : Colors.blue.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isListening
                                    ? Icons.mic
                                    : _voiceError.isNotEmpty
                                        ? Icons.error_outline
                                        : Icons.mic_none,
                                color: _isListening
                                    ? Colors.red
                                    : _voiceError.isNotEmpty
                                        ? Colors.red
                                        : Colors.blue,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _isListening
                                      ? 'Listening... Speak now'
                                      : _voiceError.isNotEmpty
                                          ? _voiceError
                                          : 'Voice input ready',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isListening
                                        ? Colors.red.shade700
                                        : _voiceError.isNotEmpty
                                            ? Colors.red.shade700
                                            : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              if (_isListening)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 12),

                      // Search Controls Row - Responsive
                      Column(
                        children: [
                          // Voice input controls row
                          if (_voiceAvailable) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isListening
                                    ? _stopVoiceInput
                                    : _startVoiceInput,
                                icon: Icon(
                                  _isListening ? Icons.stop : Icons.mic,
                                  size: 18,
                                ),
                                label: Text(
                                  _isListening
                                      ? 'Stop Listening'
                                      : 'Voice Search',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _isListening ? Colors.red : Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                          ],

                          // Search Button - Full width on mobile
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _searchController.text.trim().isNotEmpty &&
                                          !_isSearching
                                      ? () {
                                          _performSearch();
                                          _dismissKeyboard();
                                        }
                                      : null,
                              icon: _isSearching
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(Icons.search, size: 18),
                              label: Text(
                                _isSearching ? 'Searching...' : 'Search',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),

                          // Result Limit - Centered
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _resultLimit,
                                isExpanded: false,
                                items: [5, 10, 20, 50].map((limit) {
                                  return DropdownMenuItem(
                                    value: limit,
                                    child: Text(
                                      '$limit results',
                                      style: TextStyle(fontSize: 13),
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
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Results Section
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
          // Search Tips
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text(
                        'Search Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildTipItem(
                      'Use specific terms like "temperature sensor" or "compressor oil"'),
                  _buildTipItem(
                      'Search for symptoms: "not cooling properly" or "strange noise"'),
                  _buildTipItem(
                      'Include model numbers or part names when known'),
                  _buildTipItem(
                      'Try different phrasings if you don\'t find what you need'),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Quick Search Suggestions
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick search and voice section
                  Row(
                    children: [
                      Icon(Icons.touch_app, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text(
                        _voiceAvailable
                            ? 'Quick Search & Voice'
                            : 'Quick Search',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    _voiceAvailable
                        ? 'Tap any suggestion to search, or use voice input:'
                        : 'Tap any suggestion to search:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),

                  // Voice input button (prominent)
                  if (_voiceAvailable) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isListening ? _stopVoiceInput : _startVoiceInput,
                        icon: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          size: 20,
                        ),
                        label: Text(
                          _isListening ? 'Stop Listening' : 'Tap to Speak',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isListening ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Voice status
                    if (_isListening || _voiceError.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isListening
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isListening ? Icons.mic : Icons.error_outline,
                              color: _isListening ? Colors.green : Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isListening
                                    ? 'Listening... Speak your search query clearly'
                                    : _voiceError,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isListening
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_isListening)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),

                    if (_isListening || _voiceError.isNotEmpty)
                      SizedBox(height: 12),

                    Text(
                      'Or tap a suggestion below:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _searchSuggestions.map((suggestion) {
                      return ActionChip(
                        label: Text(
                          suggestion,
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () {
                          _searchController.text = suggestion;
                          _performSearch();
                          _dismissKeyboard();
                        },
                        backgroundColor: Color(0xFF1E3A8A).withOpacity(0.1),
                        labelStyle: TextStyle(color: Color(0xFF1E3A8A)),
                        padding: EdgeInsets.symmetric(horizontal: 6),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Color(0xFF1E3A8A))),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700]),
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
            'Using AI to find the most relevant information',
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
        // Results Header - More compact
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Results for',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  fontSize: 13,
                ),
              ),
              Text(
                '"$_lastQuery"',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                '${_searchResults.length} found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // Results List
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
    print('Result data: $result');
    print('Score field: ${result['score']}');
    print('Score type: ${result['score'].runtimeType}');

    final similarity = (result['score'] is String)
        ? double.tryParse(result['score']) ?? 0.0
        : result['score']?.toDouble() ?? 0.0;

    print('Similarity after conversion: $similarity');

    final relevanceColor = _getRelevanceColor(similarity);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row - Better mobile layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result['document_name'] ?? 'Unknown Document',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E3A8A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Metadata Row
                      Wrap(
                        spacing: 8,
                        children: [
                          if (result['page_number'] != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.description,
                                    size: 11, color: Colors.grey[600]),
                                SizedBox(width: 2),
                                Text(
                                  'Page ${result['page_number']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 11, color: relevanceColor),
                              SizedBox(width: 2),
                              Text(
                                _getRelevanceText(similarity),
                                style: TextStyle(
                                  color: relevanceColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: relevanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(similarity * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: relevanceColor,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Content - Better text wrapping with strict constraints
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth,
                  child: Text(
                    result['content'] ?? 'No content available',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: Colors.grey[800],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),

            SizedBox(height: 6),

            // Action Buttons - Compact row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showFullContent(result),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF1E3A8A),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(0, 28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, size: 12),
                      SizedBox(width: 4),
                      Text('View', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _copyContent(result['content'] ?? ''),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(0, 28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 12),
                      SizedBox(width: 4),
                      Text('Copy', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
      final result =
          await ApiService.searchDocuments(query, limit: _resultLimit);

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

  void _showFullContent(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result['document_name'] ?? 'Document Content',
          style: TextStyle(fontSize: 16),
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result['page_number'] != null) ...[
                  Text(
                    'Page ${result['page_number']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                Text(
                  result['content'] ?? 'No content available',
                  style: TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _copyContent(result['content'] ?? ''),
            child: Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
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
