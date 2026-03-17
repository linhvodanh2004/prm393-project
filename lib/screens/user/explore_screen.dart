import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/room_model.dart';
import '../../services/favorite_service.dart';
import 'room_details_screen.dart';
import '../../utils/format_utils.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _favService = FavoriteService();
  String _searchQuery = '';
  String? _selectedAmenity;
  double? _maxPrice;
  String? _uid;
  Set<String> _favoriteIds = {};
  final Map<String, String> _hostAddressCache = {};

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

  final List<String> _amenityOptions = [
    'wifi',
    'pool',
    'ac',
    'tv',
    'parking',
    'kitchen',
  ];

  final List<double> _priceOptions = [200000, 500000, 1000000, 2000000];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _getHostAddress(String hostId) async {
    final cached = _hostAddressCache[hostId];
    if (cached != null) return cached;
    final doc =
        await FirebaseFirestore.instance.collection('properties').doc(hostId).get();
    final data = doc.data();
    final address = (data?['address'] ?? '').toString().trim();
    if (address.isNotEmpty) {
      _hostAddressCache[hostId] = address;
      return address;
    }
    return null;
  }

  Stream<List<RoomModel>> _buildRoomStream() {
    return FirebaseFirestore.instance
        .collection('rooms')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RoomModel.fromMap(d.data(), d.id))
            .toList());
  }

  List<RoomModel> _applyFilters(List<RoomModel> rooms) {
    return rooms.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesAmenity = _selectedAmenity == null ||
          r.amenities.contains(_selectedAmenity);
      final matchesPrice =
          _maxPrice == null || r.basePrice <= _maxPrice!;
      return matchesSearch && matchesAmenity && matchesPrice;
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
          // Amenity filter chips
          ..._amenityOptions.map((a) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(a,
                      style: TextStyle(
                          color: _selectedAmenity == a
                              ? Colors.black
                              : Colors.white70,
                          fontSize: 12)),
                  selected: _selectedAmenity == a,
                  selectedColor: const Color(0xFFFFD700),
                  backgroundColor: const Color(0xFF1A1A1A),
                  checkmarkColor: Colors.black,
                  onSelected: (sel) => setState(
                      () => _selectedAmenity = sel ? a : null),
                ),
              )),
          // Price filter chips
          ..._priceOptions.map((p) {
            final label =
                '≤ ${(p / 1000).toStringAsFixed(0)}k';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label,
                    style: TextStyle(
                        color: _maxPrice == p
                            ? Colors.black
                            : Colors.white70,
                        fontSize: 12)),
                selected: _maxPrice == p,
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF1A1A1A),
                checkmarkColor: Colors.black,
                onSelected: (sel) =>
                    setState(() => _maxPrice = sel ? p : null),
              ),
            );
          }),
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
            child: Text('Lỗi tải dữ liệu',
                style: TextStyle(color: Colors.red[300])),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }

        final rooms = _applyFilters(snapshot.data!);

        if (rooms.isEmpty) {
          return const Center(
            child: Text('Không tìm thấy phòng phù hợp',
                style: TextStyle(color: Colors.white54)),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: room.images.isNotEmpty
                  ? Image.network(
                      room.images.first,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white24, size: 48),
                      ),
                    )
                  : Container(
                      height: 180,
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.meeting_room,
                          color: Colors.white24, size: 48),
                    ),
            ),
                // Heart button
                if (_uid != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _favService.toggleFavorite(
                          _uid!, room.id, isFav),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav
                              ? Colors.redAccent
                              : Colors.white70,
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
                  Text(room.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  FutureBuilder<String?>(
                    future: _getHostAddress(room.hostId),
                    builder: (context, snap) {
                      final address = (snap.data ?? '').trim();
                      if (address.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: Colors.white38),
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
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        FormatUtils.vnd(room.basePrice),
                        style: const TextStyle(
                            color: Color(0xFFFFD700), fontSize: 14),
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
                          .map((a) => Chip(
                                label: Text(a,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white70)),
                                backgroundColor: const Color(0xFF2A2A2A),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
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
