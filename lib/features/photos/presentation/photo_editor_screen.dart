import 'dart:math';
import 'package:flutter/material.dart';

class PhotoEditorScreen extends StatefulWidget {
  final String imagePath;
  const PhotoEditorScreen({super.key, required this.imagePath});
  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  double _rotation = 0;
  double _scale = 1.0;
  double _cropX = 0;
  double _cropY = 0;
  double _cropWidth = 1.0;
  double _cropHeight = 1.0;
  bool _isCropMode = false;
  String _selectedFilter = 'None';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Photo'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: () {
            // Save edited photo
            Navigator.pop(context, {'rotation': _rotation, 'scale': _scale});
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(photoFilters[_selectedFilter]!),
                child: Transform.rotate(
                angle: _rotation * pi / 180,
                child: Image.network(widget.imagePath, fit: BoxFit.contain, errorBuilder: (_, __, ___) =>
                  Container(color: theme.colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.image, size: 64)))),
              ),
              ),
            ),
          ),
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _toolButton(Icons.rotate_left, 'Rotate L', () => setState(() => _rotation -= 90)),
                _toolButton(Icons.rotate_right, 'Rotate R', () => setState(() => _rotation += 90)),
                _toolButton(Icons.flip, 'Flip', () => setState(() => _scale = _scale == 1.0 ? -1.0 : 1.0)),
                _toolButton(Icons.filter, 'Filter', () => _showFilterPicker()),
                _toolButton(Icons.crop, 'Crop', () => setState(() => _isCropMode = !_isCropMode)),
                _toolButton(Icons.restart_alt, 'Reset', () => setState(() {
                  _rotation = 0; _scale = 1.0; _cropX = 0; _cropY = 0; _cropWidth = 1.0; _cropHeight = 1.0;
                })),
              ],
            ),
          ),
          if (_selectedFilter != 'None')
            Padding(
              padding: const EdgeInsets.all(8),
              child: Chip(
                label: Text('Filter: $_selectedFilter'),
                onDeleted: () => setState(() => _selectedFilter = 'None'),
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
            ),
          if (_isCropMode) Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                const Text('X:'), Expanded(child: Slider(value: _cropX, onChanged: (v) => setState(() => _cropX = v))),
              ]),
              Row(children: [
                const Text('Y:'), Expanded(child: Slider(value: _cropY, onChanged: (v) => setState(() => _cropY = v))),
              ]),
              Row(children: [
                const Text('W:'), Expanded(child: Slider(value: _cropWidth, min: 0.1, onChanged: (v) => setState(() => _cropWidth = v))),
              ]),
              Row(children: [
                const Text('H:'), Expanded(child: Slider(value: _cropHeight, min: 0.1, onChanged: (v) => setState(() => _cropHeight = v))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  void _showFilterPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 120,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          children: photoFilters.keys.map((name) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(name),
              selected: _selectedFilter == name,
              onSelected: (_) => setState(() => _selectedFilter = name),
            ),
          )).toList(),
        ),
      ),
    );
  }
  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(8), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10)),
        ])),
      ),
    );
  }
}

// Photo filter presets (CSS-like filters applied via ColorFiltered)
const Map<String, List<double>> photoFilters = {
  'None': [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
  'Grayscale': [0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0],
  'Sepia': [0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0],
  'Invert': [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0],
  'Warm': [1.2, 0.1, 0, 0, 0, 0, 1.1, 0.1, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0, 1, 0],
  'Cool': [0.9, 0, 0.1, 0, 0, 0, 0.9, 0.1, 0, 0, 0, 0.1, 1.2, 0, 0, 0, 0, 0, 1, 0],
  'Vintage': [0.9, 0.5, 0.1, 0, 0, 0.3, 0.8, 0.1, 0, 0, 0.2, 0.3, 0.5, 0, 0, 0, 0, 0, 1, 0],
  'B&W': [1.5, 1.5, 1.5, 0, -128, 1.5, 1.5, 1.5, 0, -128, 1.5, 1.5, 1.5, 0, -128, 0, 0, 0, 1, 0],
};
