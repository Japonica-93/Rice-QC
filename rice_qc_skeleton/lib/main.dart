import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'services/analyzer.dart';
import 'widgets/boxes_painter.dart';
import 'data/labels.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RiceQcApp());
}

class RiceQcApp extends StatelessWidget {
  const RiceQcApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ThemeData.light();
    const primaryGreen = Color(0xFF0B7D3A); // close to logo green
    return MaterialApp(
      title: 'rICE qc',
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: primaryGreen,
          secondary: primaryGreen,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: primaryGreen, foregroundColor: Colors.white),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: primaryGreen),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum SampleType { rice, paddy }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  SampleType _type = SampleType.rice;
  File? _imageFile;
  List<Detection> _detections = [];
  bool _isAnalyzing = false;
  final Analyzer _analyzer = Analyzer();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? x = await _picker.pickImage(source: source, imageQuality: 95);
    if (x == null) return;
    setState(() {
      _imageFile = File(x.path);
      _detections = [];
    });
  }

  Future<void> _analyze() async {
    if (_imageFile == null) return;
    setState(() => _isAnalyzing = true);
    try {
      final dets = await _analyzer.analyze(_imageFile!, _type);
      setState(() => _detections = dets);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analyze failed: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveResult() async {
    if (_imageFile == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final out = File('${dir.path}/result_$ts.txt');
    // simple save of counts as demo
    final counts = <String, int>{};
    for (final d in _detections) {
      counts[d.label] = (counts[d.label] ?? 0) + 1;
    }
    final total = _detections.length;
    final buf = StringBuffer()
      ..writeln('rICE qc result @ ${DateTime.now()}')
      ..writeln('type=${_type.name}, total_detections=$total')
      ..writeln('counts=$counts');
    await out.writeAsString(buf.toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved summary to ${out.path}'))
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo-aan.png', height: 28),
            const SizedBox(width: 8),
            const Text('rICE qc'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleButtons(
              isSelected: [_type == SampleType.rice, _type == SampleType.paddy],
              onPressed: (i) => setState(() => _type = i == 0 ? SampleType.rice : SampleType.paddy),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('GẠO')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('LÚA')),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _imageFile == null
                  ? const Text('Chụp hoặc chọn ảnh mẫu để phân tích', style: TextStyle(fontSize: 16))
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(_imageFile!, fit: BoxFit.contain),
                        ),
                        if (_detections.isNotEmpty)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: BoxesPainter(_detections),
                            ),
                          ),
                        if (_isAnalyzing)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.25),
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                          )
                      ],
                    ),
            ),
          ),
          if (_detections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: _summaryChips(_detections),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Chụp'),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Chọn ảnh'),
            ),
            ElevatedButton.icon(
              onPressed: (_imageFile != null && !_isAnalyzing) ? _analyze : null,
              icon: const Icon(Icons.analytics),
              label: const Text('Phân tích'),
            ),
            ElevatedButton.icon(
              onPressed: _detections.isNotEmpty ? _saveResult : null,
              icon: const Icon(Icons.save_alt),
              label: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _summaryChips(List<Detection> dets) {
    final counts = <String, int>{};
    for (final d in dets) {
      counts[d.label] = (counts[d.label] ?? 0) + 1;
    }
    final total = dets.length;
    return counts.entries.map((e) {
      final pct = (e.value / max(total, 1) * 100).toStringAsFixed(1);
      return Chip(label: Text('${e.key}: ${e.value} (${pct}%)'));
    }).toList();
  }
}
