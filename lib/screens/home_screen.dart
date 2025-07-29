import 'package:flutter/material.dart';
import 'upload_screen.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardTab(),
      UploadScreen(),
      SearchScreen(),
      HistoryScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.ac_unit, size: 28),
            SizedBox(width: 8),
            Text(
              'ThermoLogic AI',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey[600],
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Documents',
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ThermoLogic AI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Industrial Refrigeration Manual Assistant'),
            SizedBox(height: 8),
            Text('• Upload PDF manuals', style: TextStyle(fontSize: 14)),
            Text('• AI-powered semantic search',
                style: TextStyle(fontSize: 14)),
            Text('• Real-time document processing',
                style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text(
              'Status: Production Ready ✅',
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  @override
  _DashboardTabState createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic>? healthData;
  Map<String, dynamic>? statsData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    final healthResult = await ApiService.checkHealth();
    final statsResult = await ApiService.getStats();

    setState(() {
      healthData = healthResult['success'] ? healthResult['data'] : null;
      statsData = statsResult['success'] ? statsResult['data'] : null;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Status',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
            ),
            SizedBox(height: 16),

            // Health Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          healthData != null ? Icons.check_circle : Icons.error,
                          color: healthData != null ? Colors.green : Colors.red,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Backend Health',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (healthData != null) ...[
                      _buildHealthItem(
                          'Status', healthData!['status'] ?? 'Unknown'),
                      _buildHealthItem(
                          'Database',
                          healthData!['services']?['database']?['status'] ??
                              'Unknown'),
                      _buildHealthItem(
                          'Vector Store',
                          healthData!['services']?['vector_store']?['status'] ??
                              'Unknown'),
                      _buildHealthItem('Environment',
                          healthData!['environment'] ?? 'Unknown'),
                    ] else
                      Text(
                        'Unable to connect to backend',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Statistics Cards
            if (statsData != null) ...[
              Text(
                'Statistics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Documents',
                      '${statsData!['documents']['total'] ?? 0}',
                      Icons.description,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Processing',
                      '${statsData!['documents']['processing'] ?? 0}',
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Completed',
                      '${statsData!['documents']['completed'] ?? 0}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Chunks',
                      '${statsData!['chunks']['total'] ?? 0}',
                      Icons.inventory,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Switch to upload tab
                      final homeState =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      homeState?.setState(() {
                        homeState._currentIndex = 1;
                      });
                    },
                    icon: Icon(Icons.upload_file),
                    label: Text('Upload Manual'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Switch to search tab
                      final homeState =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      homeState?.setState(() {
                        homeState._currentIndex = 2;
                      });
                    },
                    icon: Icon(Icons.search),
                    label: Text('Search Docs'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
