import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.appBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildUserManagement(),
          _buildAnalytics(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF111111),
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTheme.widgetBorder.withOpacity(0.25),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.iconColor),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: Colors.white70),
            selectedIcon: Icon(Icons.people, color: AppTheme.iconColor),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.analytics, color: AppTheme.iconColor),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  icon: Icons.people,
                  title: 'Total Users',
                  subtitle: 'View all users',
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _buildDashboardCard(
                  icon: Icons.book,
                  title: 'Manga Content',
                  subtitle: 'Manage uploads',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Manga management coming soon!')),
                    );
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.report,
                  title: 'Reports',
                  subtitle: 'User reports',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reports coming soon!')),
                    );
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'App settings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagement() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isAdmin', isEqualTo: false) // Only normal users
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70)),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data?.docs ?? [];

                if (users.isEmpty) {
                  return const Center(
                    child: Text('No users found',
                        style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;

                    return Card(
                      color: const Color(0xFF111111),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          userData['username'] ?? 'Unknown User',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          userData['email'] ?? 'No email',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete user',
                          icon: const Icon(Icons.delete_outline, color: Color.fromARGB(255, 129, 2, 2)),
                          onPressed: () async {
                            // Show confirmation dialog
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete user?'),
                                content: Text('Are you sure you want to delete "${userData['username'] ?? 'this user'}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            // If not confirmed, do nothing
                            if (confirm != true) return;

                            try {
                              // Delete user document from Firestore
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .delete();
                              
                              // Show success message
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Successfully deleted user "${userData['username'] ?? 'unknown'}"'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              // Show error message
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete user: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder(
              future: _getAnalyticsData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data ?? {};

                return Column(
                  children: [
                    _buildAnalyticsCard(
                      'Total Users',
                      '${data['totalUsers'] ?? 0}',
                      Icons.people,
                      Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildAnalyticsCard(
                      'Admin Users',
                      '${data['adminUsers'] ?? 0}',
                      Icons.admin_panel_settings,
                      Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildAnalyticsCard(
                      'Regular Users',
                      '${data['regularUsers'] ?? 0}',
                      Icons.person,
                      Colors.green,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF111111),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.iconColor, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF111111),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getAnalyticsData() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;
      
      int adminUsers = 0;
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data['isAdmin'] == true) {
          adminUsers++;
        }
      }
      
      final regularUsers = totalUsers - adminUsers;
      
      return {
        'totalUsers': totalUsers,
        'adminUsers': adminUsers,
        'regularUsers': regularUsers,
      };
    } catch (e) {
      return {};
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }
}
