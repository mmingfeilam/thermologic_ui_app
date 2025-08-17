import 'package:flutter/material.dart';
import 'upload_screen.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import '../services/api_service.dart';

// Company model
class Company {
  final int id;
  final String name;
  final bool isSelected;

  Company({
    required this.id,
    required this.name,
    this.isSelected = false,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      isSelected: json['isSelected'] ?? false,
    );
  }

  Company copyWith({bool? isSelected}) {
    return Company(
      id: id,
      name: name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Company> companies = [];
  late Company selectedCompany;
  bool companiesLoaded = false;
  bool isLoading = true;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => isLoading = true);

    final result = await ApiService.getCompanies();
    if (result['success']) {
      final companiesData = List<Map<String, dynamic>>.from(result['data']);
      companies = companiesData.map((data) => Company.fromJson(data)).toList();

      // Set initial selected company
      selectedCompany = companies.firstWhere(
        (company) => company.isSelected,
        orElse: () => companies.first,
      );

      // Set the company in API service
      ApiService.setCompany(selectedCompany.id);

      // Initialize screens after company is set
      _screens = [
        DashboardTab(selectedCompany: selectedCompany),
        UploadScreen(),
        SearchScreen(),
        HistoryScreen(),
      ];

      setState(() {
        companiesLoaded = true;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _onCompanyChanged(Company newCompany) {
    setState(() {
      selectedCompany = newCompany;
      ApiService.setCompany(newCompany.id);

      // Update dashboard with new company
      _screens[0] = DashboardTab(
        key: ValueKey(newCompany.id),
        selectedCompany: newCompany,
      );
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${newCompany.name}'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ThermoLogic AI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: Padding(
          padding: EdgeInsets.all(12.0),
          child: Icon(Icons.ac_unit, size: 24),
        ),
        actions: [
          // Company Dropdown
          if (companiesLoaded)
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 140),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Company>(
                        value: selectedCompany,
                        dropdownColor: Theme.of(context).primaryColor,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        icon: Icon(Icons.arrow_drop_down,
                            color: Colors.white, size: 16),
                        isExpanded: true,
                        isDense: true,
                        items: companies.map((company) {
                          return DropdownMenuItem<Company>(
                            value: company,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.business,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    company.name,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (Company? newCompany) {
                          if (newCompany != null) {
                            _onCompanyChanged(newCompany);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: companiesLoaded
          ? _screens[_currentIndex]
          : Center(child: Text('Loading...')),
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
            Text('• Multi-tenant company isolation',
                style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text(
              'Current Company: ${selectedCompany.name}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Status: Multi-Tenant Ready ✅',
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
  final Company selectedCompany;

  const DashboardTab({
    Key? key,
    required this.selectedCompany,
  }) : super(key: key);

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

  @override
  void didUpdateWidget(DashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if company changed
    if (oldWidget.selectedCompany.id != widget.selectedCompany.id) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    try {
      final healthResult = await ApiService.checkHealth();
      final statsResult = await ApiService.getStats();

      if (mounted) {
        setState(() {
          healthData = healthResult['success'] ? healthResult['data'] : null;
          statsData = statsResult['success'] ? statsResult['data'] : null;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          healthData = null;
          statsData = null;
          isLoading = false;
        });
      }
    }
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
            // Company Info Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF1E3A8A).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.business, color: Color(0xFF1E3A8A)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Company',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.selectedCompany.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ID: ${widget.selectedCompany.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

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
                          'Storage',
                          healthData!['services']?['storage']?['status'] ??
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

            // Company Statistics Cards
            if (statsData != null) ...[
              Text(
                'Company Statistics',
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
                      '${statsData!['database']?['total_documents'] ?? 0}',
                      Icons.description,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Processing',
                      '${statsData!['database']?['pending_processing'] ?? 0}',
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
                      'Total Chunks',
                      '${statsData!['database']?['total_chunks'] ?? 0}',
                      Icons.inventory,
                      Colors.purple,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Vector Store',
                      statsData!['vector_store']?['status'] == 'loaded'
                          ? 'Active'
                          : 'Inactive',
                      Icons.psychology,
                      statsData!['vector_store']?['status'] == 'loaded'
                          ? Colors.green
                          : Colors.red,
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
