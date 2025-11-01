import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/classifier.dart';

class InfoBottomSheet extends StatelessWidget {
  final ClassificationResult result;

  const InfoBottomSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isOrganic = result.isOrganic;
    final color = isOrganic ? const Color(0xFF4CAF50) : const Color(0xFF2196F3);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isOrganic ? Icons.eco : Icons.recycling,
                        color: color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOrganic ? 'SAMPAH ORGANIK' : 'SAMPAH ANORGANIK',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            'Informasi & Cara Pembuangan',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                if (isOrganic) ..._buildOrganicInfo(color) else ..._buildAnorganicInfo(color),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Mengerti',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrganicInfo(Color color) {
    return [
      _InfoSection(
        icon: Icons.category,
        title: 'Apa itu Sampah Organik?',
        description: 'Sampah organik adalah sampah yang berasal dari makhluk hidup dan dapat terurai secara alami oleh mikroorganisme.',
        color: color,
      ),
      const SizedBox(height: 16),
      _InfoSection(
        icon: Icons.list_alt,
        title: 'Contoh Sampah Organik',
        description: '• Sisa makanan (nasi, sayuran, buah)\n• Daun kering dan ranting\n• Kulit buah dan sayuran\n• Ampas kopi dan teh\n• Kertas yang tidak dilapisi plastik',
        color: color,
      ),
      const SizedBox(height: 16),
      _InfoSection(
        icon: Icons.delete_outline,
        title: 'Cara Pembuangan',
        description: '1. Pisahkan dari sampah anorganik\n2. Bisa dijadikan kompos di rumah\n3. Atau masukkan ke tempat sampah organik\n4. Pastikan tidak tercampur dengan plastik',
        color: color,
      ),
    ];
  }

  List<Widget> _buildAnorganicInfo(Color color) {
    return [
      _InfoSection(
        icon: Icons.category,
        title: 'Apa itu Sampah Anorganik?',
        description: 'Sampah anorganik adalah sampah yang tidak dapat terurai secara alami dan membutuhkan waktu sangat lama untuk hancur.',
        color: color,
      ),
      const SizedBox(height: 16),
      _InfoSection(
        icon: Icons.list_alt,
        title: 'Contoh Sampah Anorganik',
        description: '• Plastik (botol, kantong, kemasan)\n• Kaleng dan logam\n• Kertas berlapis plastik\n• Kaca dan keramik\n• Styrofoam',
        color: color,
      ),
      const SizedBox(height: 16),
      _InfoSection(
        icon: Icons.recycling,
        title: 'Cara Pembuangan',
        description: '1. Pisahkan dari sampah organik\n2. Bersihkan terlebih dahulu\n3. Masukkan ke tempat sampah anorganik\n4. Jika memungkinkan, kirim ke bank sampah\n5. Plastik & kaleng bisa didaur ulang',
        color: color,
      ),
    ];
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}