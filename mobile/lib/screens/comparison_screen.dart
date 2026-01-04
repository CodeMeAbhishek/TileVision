import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class ComparisonScreen extends StatefulWidget {
  final String originalImagePath;
  final String resultImageBase64;

  const ComparisonScreen({
    super.key,
    required this.originalImagePath,
    required this.resultImageBase64,
  });

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  bool _isSideBySide = true; // true = side by side, false = stacked

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare'),
        actions: [
          IconButton(
            icon: Icon(_isSideBySide ? Icons.view_agenda : Icons.view_column),
            onPressed: () {
              setState(() {
                _isSideBySide = !_isSideBySide;
              });
            },
            tooltip: _isSideBySide ? 'Stack View' : 'Side by Side',
          ),
        ],
      ),
      body: _isSideBySide ? _buildSideBySide() : _buildStacked(),
    );
  }

  Widget _buildSideBySide() {
    return Row(
      children: [
        // Original (Before)
        Expanded(
          child: Container(
            color: Colors.black,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue.shade700,
                  width: double.infinity,
                  child: const Text(
                    'BEFORE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(widget.originalImagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Divider
        Container(
          width: 2,
          color: Colors.grey.shade300,
        ),
        // Result (After)
        Expanded(
          child: Container(
            color: Colors.black,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.green.shade700,
                  width: double.infinity,
                  child: const Text(
                    'AFTER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      base64Decode(widget.resultImageBase64),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStacked() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Original (Before)
          Container(
            color: Colors.black,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue.shade700,
                  width: double.infinity,
                  child: const Text(
                    'BEFORE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(widget.originalImagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 2,
            color: Colors.grey.shade300,
          ),
          // Result (After)
          Container(
            color: Colors.black,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.green.shade700,
                  width: double.infinity,
                  child: const Text(
                    'AFTER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(
                    base64Decode(widget.resultImageBase64),
                    fit: BoxFit.contain,
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

