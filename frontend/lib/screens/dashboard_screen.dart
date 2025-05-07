
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../providers/project_provider.dart';
// import '../providers/notification_provider.dart';
// import '../widgets/app_drawer.dart';
// import './project_list_screen.dart';
// import './profile_screen.dart';
// import './notifications_screen.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key}); 
//   static const routeName = '/dashboard';

//   @override
//   _DashboardScreenState createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   var _isInit = true;
//   var _isLoading = false;
//   int _selectedIndex = 0;

//   @override
//   void didChangeDependencies() {
//     if (_isInit) {
//       setState(() {
//         _isLoading = true;
//       });
      
//       Provider.of<ProjectProvider>(context).fetchProjects().then((_) {
//         Provider.of<NotificationProvider>(context, listen: false).fetchNotifications().then((_) {
//           setState(() {
//             _isLoading = false;
//           });
//         });
//       });
      
//       _isInit = false;
//     }
//     super.didChangeDependencies();
//   }

//   final List<Widget> _pages = [
//     ProjectListScreen(),
//     NotificationsScreen(),
//     ProfileScreen(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final unreadCount = Provider.of<NotificationProvider>(context).unreadCount;
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Project Management'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () async {
//               setState(() {
//                 _isLoading = true;
//               });
//               await Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
//               await Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
//               setState(() {
//                 _isLoading = false;
//               });
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () {
//               Provider.of<AuthProvider>(context, listen: false).logout();
//             },
//           ),
//         ],
//       ),
//       drawer: AppDrawer(),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _pages[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         items: <BottomNavigationBarItem>[
//           const BottomNavigationBarItem(
//             icon: Icon(Icons.folder),
//             label: 'Projects',
//           ),
//           BottomNavigationBarItem(
//             icon: Badge(
//               label: unreadCount > 0 ? Text(unreadCount.toString()) : null,
//               isLabelVisible: unreadCount > 0,
//               child: const Icon(Icons.notifications),
//             ),
//             label: 'Notifications',
//           ),
//           const BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/app_drawer.dart';
import './project_list_screen.dart';
import './profile_screen.dart';
import './notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  static const routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var _isInit = true;
  var _isLoading = false;
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _loadInitialData();
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
      await Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: ${error.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
      await Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh: ${error.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  final List<Widget> _pages = [
    const ProjectListScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = Provider.of<NotificationProvider>(context).unreadCount;
    final currentUser = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: const Text('Logout'),
              ),
              if ((currentUser?.isAdmin ?? false) || (currentUser?.isSuperAdmin ?? false))
                PopupMenuItem(
                  value: 'admin',
                  child: const Text('Admin Panel'),
                ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                Provider.of<AuthProvider>(context, listen: false).logout();
              } else if (value == 'admin') {
                // Navigate to admin panel
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: _pages[_selectedIndex],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}