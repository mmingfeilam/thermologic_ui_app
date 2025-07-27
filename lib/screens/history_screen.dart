import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _documents = [];
  bool _isLoading = true;
  String _filterStatus = 'all';
  String _sortBy = 'newest';

  final List<String> _statusFilters = [
    'all',
    'pending',
    'processing',
    'completed',
    'failed',
  ];

  final List<String> _sortOptions = [
    'newest',
    'oldest',
    'name',
    'size',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      print('Fetching documents from: ${ApiService.baseUrl}/api/v1/documents');
      final result = await ApiService.getDocuments();
      print('API result: $result');

      setState(() {
        _isLoading = false;
        if (result['success']) {
          _documents = result['data']['documents'] ?? [];
          print('Loaded ${_documents.length} documents');
          if (_documents.isNotEmpty) {
            print('First document: ${_documents[0]}');
          }
          _sortDocuments();
        } else {
          print('API call failed: ${result['error']}');
        }
      });
    } catch (e) {
      print('Exception loading documents: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load documents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sortDocuments() {
    _documents.sort((a, b) {
      switch (_sortBy) {
        case 'oldest':
          return (a['upload_time'] ?? '').compareTo(b['upload_time'] ?? '');
        case 'name':
          return (a['filename'] ?? '')
              .toLowerCase()
              .compareTo((b['filename'] ?? '').toLowerCase());
        case 'size':
          return (b['file_size'] ?? 0).compareTo(a['file_size'] ?? 0);
        case 'newest':
        default:
          return (b['upload_time'] ?? '').compareTo(a['upload_time'] ?? '');
      }
    });
  }

  List<dynamic> get _filteredDocuments {
    if (_filterStatus == 'all') return _documents;
    return _documents
        .where(
            (doc) => doc['processing_status']?.toLowerCase() == _filterStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Documents',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadDocuments,
                tooltip: 'Refresh documents',
              ),
            ],
          ),

          SizedBox(height: 16),

          // Filters and Sort Row
          Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  // Status Filter
                  Row(
                    children: [
                      Text(
                        'Filter by Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: _statusFilters.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_formatStatusText(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                    },
                  ),

                  SizedBox(height: 12),

                  // Sort Options
                  Row(
                    children: [
                      Text(
                        'Sort by',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(_formatSortText(option)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                        _sortDocuments();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Documents List
          Expanded(
            child: _buildDocumentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final filteredDocs = _filteredDocuments;

    if (_documents.isEmpty) {
      return _buildEmptyState();
    }

    if (filteredDocs.isEmpty) {
      return _buildNoFilterResultsState();
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        itemCount: filteredDocs.length,
        itemBuilder: (context, index) {
          final doc = filteredDocs[index];
          return _buildDocumentCard(doc);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No documents found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upload your first PDF manual to get started',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to upload tab - simplified approach
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Go to Upload tab to add documents'),
                ),
              );
            },
            icon: Icon(Icons.upload_file),
            label: Text('Upload Document'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No documents match your filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try changing the status filter',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _filterStatus = 'all';
              });
            },
            icon: Icon(Icons.clear_all),
            label: Text('Show All Documents'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    // Debug: Print the document data
    print('Document data: $doc');
    print('Filename field: ${doc['filename']}');
    print('Keys available: ${doc.keys.toList()}');

    final displayName = doc['filename'] ?? 'Unknown File';
    print('Display name: $displayName');

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
                    doc['filename'] ?? 'Unknown File',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                _buildStatusChip(doc['processing_status'] ?? 'unknown'),
              ],
            ),

            SizedBox(height: 8),

            // Metadata Row 1
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  doc['user_id'] ?? 'Unknown User',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  _formatDateTime(doc['upload_time']),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            SizedBox(height: 4),

            // Metadata Row 2
            Row(
              children: [
                if (doc['file_size'] != null) ...[
                  Icon(Icons.file_copy, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    _formatFileSize(doc['file_size']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 16),
                ],
                if (doc['chunk_count'] != null) ...[
                  Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    '${doc['chunk_count']} chunks',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),

            // Processing Info
            if (doc['text_extraction_method'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.text_fields, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Extracted via ${doc['text_extraction_method']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (doc['text_quality_score'] != null) ...[
                    SizedBox(width: 8),
                    Text(
                      '(Quality: ${(doc['text_quality_score'] * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (doc['processing_status'] == 'failed') ...[
                  OutlinedButton.icon(
                    onPressed: () => _reprocessDocument(doc['id']),
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () => _showDocumentDetails(doc),
                  icon: Icon(Icons.info, size: 16),
                  label: Text('Details'),
                ),
                SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _deleteDocument(doc['id'], doc['filename']),
                  icon: Icon(Icons.delete, size: 16),
                  label: Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'processing':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'pending':
        color = Colors.blue;
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatusText(String status) {
    switch (status) {
      case 'all':
        return 'All Documents';
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  String _formatSortText(String sort) {
    switch (sort) {
      case 'newest':
        return 'Newest First';
      case 'oldest':
        return 'Oldest First';
      case 'name':
        return 'Name A-Z';
      case 'size':
        return 'Size (Large-Small)';
      default:
        return sort;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Unknown';
    try {
      // Parse the datetime string and handle microseconds
      DateTime dt;
      if (dateTime.contains('.')) {
        // Remove microseconds if present (keep only 3 decimal places)
        final parts = dateTime.split('.');
        final cleanDateTime = '${parts[0]}.${parts[1].substring(0, 3)}Z';
        dt = DateTime.parse(cleanDateTime).toLocal();
      } else {
        dt = DateTime.parse(dateTime).toLocal();
      }

      final now = DateTime.now();
      final difference = now.difference(dt);

      print(
          'DateTime parsing - Original: $dateTime, Parsed: $dt, Now: $now, Difference: ${difference.inMinutes} minutes');

      if (difference.inDays > 7) {
        return '${dt.day}/${dt.month}/${dt.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('DateTime parsing error: $e for input: $dateTime');
      return 'Unknown';
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown';

    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> _reprocessDocument(int documentId) async {
    try {
      final result = await ApiService.reprocessDocument(documentId);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document reprocessing started'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDocuments(); // Refresh the list
      } else {
        throw Exception('Failed to reprocess document');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reprocess document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDocument(int documentId, String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "$filename"?\n\nThis action cannot be undone and will remove the document from search results.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await ApiService.deleteDocument(documentId);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDocuments(); // Refresh the list
        } else {
          throw Exception('Failed to delete document');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDocumentDetails(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Document Details'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('ID', '${doc['id']}'),
                _buildDetailRow('Filename', doc['filename'] ?? 'Unknown'),
                _buildDetailRow('User ID', doc['user_id'] ?? 'Unknown'),
                _buildDetailRow('File Size', _formatFileSize(doc['file_size'])),
                _buildDetailRow(
                    'Upload Time', _formatDateTime(doc['upload_time'])),
                _buildDetailRow(
                    'Status', doc['processing_status'] ?? 'Unknown'),
                if (doc['text_extraction_method'] != null)
                  _buildDetailRow(
                      'Extraction Method', doc['text_extraction_method']),
                if (doc['text_quality_score'] != null)
                  _buildDetailRow('Text Quality',
                      '${(doc['text_quality_score'] * 100).toStringAsFixed(1)}%'),
                _buildDetailRow('Chunk Count', '${doc['chunk_count'] ?? 0}'),
                if (doc['metadata_json'] != null) ...[
                  SizedBox(height: 12),
                  Text('Metadata:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      doc['metadata_json'],
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
