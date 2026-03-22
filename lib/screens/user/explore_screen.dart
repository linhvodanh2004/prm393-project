import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/room_model.dart';
import '../../services/favorite_service.dart';
import '../../services/room_service.dart';
import 'room_details_screen.dart';
import '../../utils/format_utils.dart';

class PriceRange {
  final String label;
  final double? min;
  final double? max;
  PriceRange(this.label, this.min, this.max);
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _favService = FavoriteService();
  String _searchQuery = '';
  PriceRange? _selectedPriceRange;
  String? _uid;
  Set<String> _favoriteIds = {};
  final Map<String, String> _hostAddressCache = {};

  // For Geospatial Search
  double? _selectedRadius;
  double? _userLat;
  double? _userLng;
  final List<double> _radiusOptions = [5.0, 10.0, 20.0];

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid != null) {
      _favService.streamFavoriteIds(_uid!).listen((ids) {
        if (mounted) setState(() => _favoriteIds = ids.toSet());
      });
    }
  }

  final List<PriceRange> _priceRanges = [
    PriceRange('100k - 200k', 100000, 200000),
    PriceRange('200k - 500k', 200000, 500000),
    PriceRange('> 500k', 500000, null),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _getHostAddress(String hostId) async {
    final cached = _hostAddressCache[hostId];
    if (cached != null) return cached;
    final doc = await FirebaseFirestore.instance
        .collection('properties')
        .doc(hostId)
        .get();
    final data = doc.data();
    final address = (data?['address'] ?? '').toString().trim();
    if (address.isNotEmpty) {
      _hostAddressCache[hostId] = address;
      return address;
    }
    return null;
  }

  Future<void> _selectRadius(double? radius) async {
    if (radius != null) {
      if (_userLat == null || _userLng == null) {
        // Yêu cầu quyền và lấy vị trí
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vui lòng bật Dịch vụ định vị')),
            );
          return;
        }
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Từ chối quyền định vị')),
              );
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quyền định vị bị từ chối vĩnh viễn.'),
              ),
            );
          return;
        }

        // Đã có quyền, lấy vị trí hiện tại
        try {
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đang lấy vị trí...')));
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          print(
            'Current Location: lat=${position.latitude}, lng=${position.longitude}',
          );
          setState(() {
            _userLat = position.latitude;
            _userLng = position.longitude;
            _selectedRadius = radius;
          });
          if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        } catch (e) {
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Lỗi định vị: $e')));
        }
      } else {
        setState(() {
          _selectedRadius = radius;
        });
      }
    } else {
      setState(() {
        _selectedRadius = null;
      });
    }
  }

  Stream<List<RoomModel>> _buildRoomStream() {
    if (_selectedRadius != null && _userLat != null && _userLng != null) {
      // Truy vấn không gian (Geospatial) bằng geoflutterfire_plus
      return RoomService().getRoomsWithinRadius(
        lat: _userLat!,
        lng: _userLng!,
        radiusInKm: _selectedRadius!,
      );
    }

    // Truy vấn mặc định (Toàn quốc)
    return FirebaseFirestore.instance
        .collection('rooms')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => RoomModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  String? _getDistanceString(RoomModel room) {
    if (_userLat == null || _userLng == null) return null;
    if (room.location == null) return null;
    final geoPoint = room.location!['geopoint'];
    if (geoPoint is! GeoPoint) return null;

    final distanceInMeters = Geolocator.distanceBetween(
      _userLat!,
      _userLng!,
      geoPoint.latitude,
      geoPoint.longitude,
    );

    if (distanceInMeters < 1000) {
      return 'Cách đây ${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return 'Cách đây ${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  List<RoomModel> _applyFilters(List<RoomModel> rooms) {
    return rooms.where((r) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPrice =
          _selectedPriceRange == null ||
          ((_selectedPriceRange!.min == null ||
                  r.basePrice >= _selectedPriceRange!.min!) &&
              (_selectedPriceRange!.max == null ||
                  r.basePrice <= _selectedPriceRange!.max!));
      return matchesSearch && matchesPrice;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Khám phá', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRow(),
          Expanded(child: _buildRoomList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm phòng...',
          hintStyle: TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          // Radius filter chips
          ..._radiusOptions.map((r) {
            final isSelected = _selectedRadius == r;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: isSelected
                    ? const Icon(Icons.near_me, size: 16, color: Colors.black)
                    : const Icon(
                        Icons.near_me,
                        size: 16,
                        color: Colors.white70,
                      ),
                label: Text(
                  'Gần tôi (<${r.toInt()}km)',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF1A1A1A),
                checkmarkColor: Colors.black,
                onSelected: (sel) => _selectRadius(sel ? r : null),
              ),
            );
          }),
          // Price filter chips
          ..._priceRanges.map(
            (pr) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  pr.label,
                  style: TextStyle(
                    color: _selectedPriceRange == pr
                        ? Colors.black
                        : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                selected: _selectedPriceRange == pr,
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF1A1A1A),
                checkmarkColor: Colors.black,
                onSelected: (sel) =>
                    setState(() => _selectedPriceRange = sel ? pr : null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    return StreamBuilder<List<RoomModel>>(
      stream: _buildRoomStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi tải dữ liệu',
              style: TextStyle(color: Colors.red[300]),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          );
        }

        final rooms = _applyFilters(snapshot.data!);

        if (rooms.isEmpty) {
          return const Center(
            child: Text(
              'Không tìm thấy phòng phù hợp',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFFFFD700),
          backgroundColor: const Color(0xFF1A1A1A),
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) =>
                _buildRoomCard(context, rooms[index]),
          ),
        );
      },
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    final isFav = _favoriteIds.contains(room.id);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RoomDetailsScreen(room: room)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with heart overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: room.images.isNotEmpty
                      ? Image.network(
                          room.images.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 180,
                                color: const Color(0xFF2A2A2A),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white24,
                                  size: 48,
                                ),
                              ),
                        )
                      : Container(
                          height: 180,
                          color: const Color(0xFF2A2A2A),
                          child: const Icon(
                            Icons.meeting_room,
                            color: Colors.white24,
                            size: 48,
                          ),
                        ),
                ),
                // Heart button
                if (_uid != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () =>
                          _favService.toggleFavorite(_uid!, room.id, isFav),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final distanceStr = _getDistanceString(room);
                      if (distanceStr != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.near_me_outlined,
                                size: 14,
                                color: Colors.white38,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  distanceStr,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return FutureBuilder<String?>(
                        future: _getHostAddress(room.hostId),
                        builder: (context, snap) {
                          final address = (snap.data ?? '').trim();
                          if (address.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Colors.white38,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        FormatUtils.vnd(room.basePrice),
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ' / giờ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (room.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: room.amenities
                          .take(4)
                          .map(
                            (a) => Chip(
                              label: Text(
                                a,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                              backgroundColor: const Color(0xFF2A2A2A),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
