import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../data/models/trend_models.dart';
import '../../data/repositories/trend_repository.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({Key? key}) : super(key: key);

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  late TrendRepository _repository;
  String _selectedFormat = 'Excel (.xlsx)';
  TopKeywordDto? _selectedKeyword;
  
  Future<List<TopKeywordDto>>? _keywordsFuture;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _repository = TrendRepository(dio: Dio());
    _loadKeywords();
  }

  void _loadKeywords() {
    setState(() {
      _keywordsFuture = _repository.getTopKeywords();
    });
  }

  Future<void> _downloadReport() async {
    if (_selectedKeyword == null) return;
    
    setState(() {
      _isDownloading = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final extension = _selectedFormat.contains('.csv') ? '.csv' : '.xlsx';
      final fileName = 'Report_${_selectedKeyword!.keywordTerm.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savePath = '${directory.path}/$fileName';

      await _repository.downloadReport(_selectedKeyword!.keywordId, savePath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report downloaded successfully! Opening file...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      await OpenFilex.open(savePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải báo cáo: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Export Report', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Select Keyword to Export'),
            const SizedBox(height: 16),
            _buildKeywordDropdown(),
            const SizedBox(height: 24),
            _buildSectionTitle('Select Format'),
            const SizedBox(height: 16),
            _buildFormatSelector(),
            const SizedBox(height: 32),
            _buildDownloadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
    );
  }

  Widget _buildKeywordDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: FutureBuilder<List<TopKeywordDto>>(
        future: _keywordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
          } else if (snapshot.hasData) {
            final keywords = snapshot.data!;
            return DropdownButtonHideUnderline(
              child: DropdownButton<TopKeywordDto>(
                value: _selectedKeyword,
                hint: Text('Choose a keyword...', style: GoogleFonts.inter(color: Colors.white54)),
                dropdownColor: const Color(0xFF1E1E1E),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                items: keywords.map((keyword) {
                  return DropdownMenuItem<TopKeywordDto>(
                    value: keyword,
                    child: Text(keyword.keywordTerm),
                  );
                }).toList(),
                onChanged: (TopKeywordDto? newValue) {
                  setState(() {
                    _selectedKeyword = newValue;
                  });
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Row(
      children: [
        Expanded(child: _buildFormatOption('Excel (.xlsx)', Icons.table_chart)),
        const SizedBox(width: 16),
        Expanded(child: _buildFormatOption('CSV (.csv)', Icons.list_alt)),
      ],
    );
  }

  Widget _buildFormatOption(String format, IconData icon) {
    final isSelected = _selectedFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = format),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.purpleAccent : Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.purpleAccent : Colors.white54, size: 32),
            const SizedBox(height: 8),
            Text(
              format,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_selectedKeyword == null || _isDownloading) ? null : _downloadReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purpleAccent,
          disabledBackgroundColor: Colors.purpleAccent.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isDownloading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('Download Analytical Report', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
