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
              child: Transform.rotate(
                angle: _rotation * pi / 180,
                child: Image.network(widget.imagePath, fit: BoxFit.contain, errorBuilder: (_, __, ___) =>
                  Container(color: theme.colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.image, size: 64)))),
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
                _toolButton(Icons.crop, 'Crop', () => setState(() => _isCropMode = !_isCropMode)),
                _toolButton(Icons.restart_alt, 'Reset', () => setState(() {
                  _rotation = 0; _scale = 1.0; _cropX = 0; _cropY = 0; _cropWidth = 1.0; _cropHeight = 1.0;
                })),
              ],
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
