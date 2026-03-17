import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/room_model.dart';
import '../../models/daily_price_model.dart';
import '../../services/room_service.dart';
import '../../widgets/common/notification_badge_icon.dart';
import '../../utils/format_utils.dart';

class HostCalendarScreen extends StatefulWidget {
  const HostCalendarScreen({super.key});

  @override
  State<HostCalendarScreen> createState() => _HostCalendarScreenState();
}

class _HostCalendarScreenState extends State<HostCalendarScreen> {
  final String? _hostId = FirebaseAuth.instance.currentUser?.uid;
  final RoomService _roomService = RoomService();

  RoomModel? _selectedRoom;
  List<RoomModel> _rooms = [];
  bool _isLoadingRooms = true;
  StreamSubscription<List<RoomModel>>? _roomsSub;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, DailyPriceModel> _dailyPricesMap = {};

  final TextEditingController _priceController = TextEditingController();
  bool _isEditingBlocked = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _roomsSub?.cancel();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    if (_hostId == null) return;
    try {
      _roomsSub = _roomService.getRoomsByHost(_hostId!).listen((rooms) {
        if (mounted) {
          setState(() {
            _rooms = rooms;
            _isLoadingRooms = false;
            if (_rooms.isNotEmpty && _selectedRoom == null) {
              _selectedRoom = _rooms.first;
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRooms = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải phòng: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // Normalize date to ignore time component for Map keys
  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  void _showEditDayDialog(DateTime date, DailyPriceModel? existingData) {
    _priceController.text = existingData != null
        ? existingData.price.toStringAsFixed(0)
        : _selectedRoom!.basePrice.toStringAsFixed(0);
    _isEditingBlocked = existingData?.isBlocked ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text(
                'Cập nhật ngày ${FormatUtils.dateVi(date)}',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Giá cho đêm này (VNĐ)',
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFD4A853)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Đóng phòng (Không đón khách)',
                      style: TextStyle(color: Colors.white70),
                    ),
                    value: _isEditingBlocked,
                    activeColor: const Color(0xFFD4A853),
                    onChanged: (val) {
                      setDialogState(() => _isEditingBlocked = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                  ElevatedButton(
                  onPressed: () async {
                    final price = double.tryParse(_priceController.text.trim());
                    if (price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập giá hợp lệ'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    // Map dialog state to RoomService's DailyPriceModel
                    final dailyPrice = DailyPriceModel(
                      id: '',
                      roomId: _selectedRoom!.id,
                      date: date,
                      price: price,
                      isBlocked: _isEditingBlocked,
                    );
                    await _roomService.setDailyPrice(dailyPrice);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã cập nhật lịch phòng')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A853),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hostId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: Text(
            'Vui lòng đăng nhập',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Lịch phòng', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoadingRooms
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            )
          : _rooms.isEmpty
          ? const Center(
              child: Text(
                'Bạn chưa có phòng nào. Hãy tạo phòng trước.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : Column(
              children: [
                // Room Selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: const Color(0xFF1A1A1A),
                  child: DropdownButtonFormField<RoomModel>(
                    dropdownColor: const Color(0xFF2A2A2A),
                    value: _selectedRoom,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.hotel, color: Color(0xFFD4A853)),
                    ),
                    items: _rooms.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(
                          r.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedRoom = val;
                        _selectedDay = null; // reset selection
                      });
                    },
                  ),
                ),

                // Calendar Stream
                Expanded(
                  child: StreamBuilder<List<DailyPriceModel>>(
                    stream: _selectedRoom == null
                        ? const Stream.empty()
                        : _roomService.getDailyPrices(
                            _selectedRoom!.id,
                          ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        _dailyPricesMap.clear();
                        for (var item in snapshot.data!) {
                          _dailyPricesMap[_normalizeDate(item.date)] = item;
                        }
                      }

                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Card(
                            color: const Color(0xFF1A1A1A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TableCalendar(
                                firstDay: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDay: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) =>
                                    isSameDay(_selectedDay, day),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  });
                                  final normalized = _normalizeDate(
                                    selectedDay,
                                  );
                                  _showEditDayDialog(
                                    normalized,
                                    _dailyPricesMap[normalized],
                                  );
                                },
                                onPageChanged: (focusedDay) {
                                  _focusedDay = focusedDay;
                                },
                                calendarStyle: const CalendarStyle(
                                  defaultTextStyle: TextStyle(
                                    color: Colors.white,
                                  ),
                                  weekendTextStyle: TextStyle(
                                    color: Colors.white70,
                                  ),
                                  outsideTextStyle: TextStyle(
                                    color: Colors.white30,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: Color(0xFFD4A853),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                headerStyle: const HeaderStyle(
                                  titleTextStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  formatButtonVisible: false,
                                  leftChevronIcon: Icon(
                                    Icons.chevron_left,
                                    color: Colors.white,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                  ),
                                ),
                                calendarBuilders: CalendarBuilders(
                                  markerBuilder: (context, date, events) {
                                    final normalized = _normalizeDate(date);
                                    final dailyData =
                                        _dailyPricesMap[normalized];

                                    if (dailyData != null) {
                                      return Positioned(
                                        bottom: 1,
                                        child: Text(
                                          dailyData.isBlocked
                                              ? 'Khóa'
                                              : FormatUtils.vndCompact(dailyData.price),
                                          style: TextStyle(
                                            color: dailyData.isBlocked
                                                ? Colors.redAccent
                                                : const Color(0xFFD4A853),
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
