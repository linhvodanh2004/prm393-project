import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../profile/user_details_screen.dart';

// User Screens
import '../user/explore_screen.dart';
import '../user/favorites_screen.dart';
import '../user/user_bookings_screen.dart';
import '../user/user_vouchers_screen.dart';
import '../chat/chat_list_screen.dart';

// Host Screens
import '../host/host_dashboard_screen.dart';
import '../host/manage_rooms_screen.dart';
import '../host/host_bookings_screen.dart';
import '../host/host_calendar_screen.dart';

// Admin Screens
import '../admin/manage_users_screen.dart';
import '../admin/admin_rooms_screen.dart';
import '../admin/admin_bookings_screen.dart';
import '../admin/admin_payments_screen.dart';

// Voucher Screens (shared)
import '../host/manage_vouchers_screen.dart';

// Notification Screen
import '../notifications/notification_screen.dart';


class HomeScreen extends StatefulWidget {
  final UserModel userModel;

  const HomeScreen({super.key, required this.userModel});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Wraps a tab child so it is only built when first shown, then kept alive.
class _LazyTab extends StatefulWidget {
  final Widget child;
  const _LazyTab({required this.child});

  @override
  State<_LazyTab> createState() => _LazyTabState();
}

class _LazyTabState extends State<_LazyTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = widget.userModel.role;
    final List<Widget> pages = _buildPagesForRole(role);
    final List<BottomNavigationBarItem> navItems = _buildNavItemsForRole(role);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            tooltip: 'Tin nhắn',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Thông báo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D0D0D),
      body: IndexedStack(
        index: _currentIndex,
        children: pages.map((p) => _LazyTab(child: p)).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF111111),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFD4A853),
          unselectedItemColor: Colors.white.withValues(alpha: 0.4),
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: navItems,
        ),
      ),
    );
  }

  List<Widget> _buildPagesForRole(String role) {
    switch (role) {
      case 'ADMIN':
        return const [
          ManageUsersScreen(),
          AdminRoomsScreen(),
          AdminBookingsScreen(),
          AdminPaymentsScreen(),
          ManageVouchersScreen(role: 'ADMIN'),
          UserDetailsScreen(),
        ];
      case 'HOST':
        return const [
          HostDashboardScreen(),
          ManageRoomsScreen(),
          HostBookingsScreen(),
          HostCalendarScreen(),
          ManageVouchersScreen(role: 'HOST'),
          UserDetailsScreen(),
        ];
      case 'USER':
      default:
        return const [
          ExploreScreen(),
          FavoritesScreen(),
          UserVouchersScreen(),
          UserBookingsScreen(),
          UserDetailsScreen(),
        ];
    }
  }

  List<BottomNavigationBarItem> _buildNavItemsForRole(String role) {
    switch (role) {
      case 'ADMIN':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people_rounded),
            label: 'Người dùng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room_outlined),
            activeIcon: Icon(Icons.meeting_room_rounded),
            label: 'Phòng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note_rounded),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments_rounded),
            label: 'Thanh toán',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer_rounded),
            label: 'Voucher',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ];

      case 'HOST':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront_rounded),
            label: 'Phòng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note_rounded),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer_rounded),
            label: 'Voucher',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ];

      case 'USER':
      default:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Khám phá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer_rounded),
            label: 'Voucher',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.airplane_ticket_outlined),
            activeIcon: Icon(Icons.airplane_ticket),
            label: 'Chuyến đi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ];
    }
  }
}
