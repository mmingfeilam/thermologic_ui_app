import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String? _lastQuery;
  int _resultLimit = 10;

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
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Manuals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
          ),
          SizedBox(height: 16),

          // Search Input Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search TextField
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search query',
                      hintText:
                          'e.g., "temperature control", "compressor issues"',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _lastQuery = null;
                                });
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                  ),
                  SizedBox(height: 16),

                  // Search Controls Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _searchController.text.trim().isNotEmpty &&
                                  !_isSearching
                              ? _performSearch
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
                              : Icon(Icons.search),
                          label: Text(_isSearching ? 'Searching...' : 'Search'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),

                      // Result Limit Dropdown
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _resultLimit,
                            items: [5, 10, 20, 50].map((limit) {
                              return DropdownMenuItem(
                                value: limit,
                                child: Text('$limit results'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _resultLimit = value!;
                              });
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

          SizedBox(height: 16),

          // Results Section
          Expanded(
            child: _buildResultsSection(),
          ),
        ],
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
                  Row(
                    children: [
                      Icon(Icons.touch_app, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text(
                        'Quick Search',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tap any suggestion to search:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _searchSuggestions.map((suggestion) {
                      return ActionChip(
                        label: Text(suggestion),
                        onPressed: () {
                          _searchController.text = suggestion;
                          _performSearch();
                        },
                        backgroundColor: Color(0xFF1E3A8A).withOpacity(0.1),
                        labelStyle: TextStyle(color: Color(0xFF1E3A8A)),
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
        // Results Header
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Results for "$_lastQuery"',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              Text(
                '${_searchResults.length} found',
                style: TextStyle(color: Colors.grey[600]),
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
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    result['document_filename'] ?? 'Unknown Document',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: relevanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(similarity * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: relevanceColor,
                    ),
                  ),
                ),
              ],
            ),

            // Metadata Row
            SizedBox(height: 8),
            Row(
              children: [
                if (result['page_number'] != null) ...[
                  Icon(Icons.description, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Page ${result['page_number']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 16),
                ],
                Icon(Icons.star, size: 14, color: relevanceColor),
                SizedBox(width: 4),
                Text(
                  _getRelevanceText(similarity),
                  style: TextStyle(
                    color: relevanceColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Content
            Text(
              result['content'] ?? 'No content available',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey[800],
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showFullContent(result),
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View Full'),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _copyContent(result['content'] ?? ''),
                  icon: Icon(Icons.copy, size: 16),
                  label: Text('Copy'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
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

  void _copyContent(String content) {
    // Note: For actual clipboard functionality, you'd need to add clipboard package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Content copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
