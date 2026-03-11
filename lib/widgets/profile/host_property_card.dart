import 'package:flutter/material.dart';
import '../../models/property_model.dart';
import '../../screens/host/profile/edit_property_screen.dart';

class HostPropertyCard extends StatelessWidget {
  final PropertyModel? property;
  final String hostId;
  final VoidCallback onDataChanged;

  const HostPropertyCard({
    Key? key,
    required this.property,
    required this.hostId,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Cover Image area
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              image:
                  property?.coverImage != null &&
                      property!.coverImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(property!.coverImage),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: const Color(0xFF2A2A2A),
            ),
            child: property?.coverImage == null || property!.coverImage.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.business,
                      size: 40,
                      color: Colors.white24,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1A1A1A).withOpacity(0.9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        property?.title != null && property!.title.isNotEmpty
                            ? property!.title
                            : 'Chưa cập nhật tên Nhà trọ/Khách sạn',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFFD4A853),
                        size: 20,
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditPropertyScreen(
                              currentProperty: property,
                              hostId: hostId,
                            ),
                          ),
                        );
                        if (result == true) {
                          onDataChanged();
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (property?.address != null &&
                    property!.address.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.blueAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          property!.address,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                if (property?.description != null &&
                    property!.description.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blueAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          property!.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
