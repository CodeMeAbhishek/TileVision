import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../models/project.dart';
import '../models/tile.dart';
import '../services/project_service.dart';
import '../helpers/responsive_helper.dart';
import 'result_screen.dart';
import 'comparison_screen.dart';

class ProjectHistoryScreen extends StatefulWidget {
  const ProjectHistoryScreen({super.key});

  @override
  State<ProjectHistoryScreen> createState() => _ProjectHistoryScreenState();
}

class _ProjectHistoryScreenState extends State<ProjectHistoryScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projects = await ProjectService.loadProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load projects: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ProjectService.deleteProject(project.id);
        _loadProjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllProjects() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Projects'),
        content: const Text('Are you sure you want to delete all saved projects? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ProjectService.clearAllProjects();
        _loadProjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All projects cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project History'),
        actions: [
          if (_projects.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllProjects,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved projects',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save projects from the result screen',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProjects,
                  child: ListView.builder(
                    padding: ResponsiveHelper.getPadding(context),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      final project = _projects[index];
                      final spacing = ResponsiveHelper.getSpacing(context);
                      final isMobile = ResponsiveHelper.isMobile(context);
                      
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: spacing,
                          vertical: spacing / 2,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(project.resultImageBase64),
                              width: isMobile ? 60 : 80,
                              height: isMobile ? 60 : 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            project.tileName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Size: ${project.tileSize} | ₹${project.tilePrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                ),
                              ),
                              Text(
                                '${_formatDate(project.createdAt)}',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getFontSize(context, mobile: 11, tablet: 12, desktop: 14),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 20),
                                    SizedBox(width: 8),
                                    Text('View'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'compare',
                                child: Row(
                                  children: [
                                    Icon(Icons.compare_arrows, size: 20),
                                    SizedBox(width: 8),
                                    Text('Compare'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'view') {
                                // Create tile object from project data
                                final tile = Tile(
                                  id: project.tileId,
                                  name: project.tileName,
                                  imageUrl: '', // Not needed for viewing
                                  size: project.tileSize,
                                  price: project.tilePrice,
                                );
                                
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ResultScreen(
                                      resultImageBase64: project.resultImageBase64,
                                      originalImagePath: project.originalImagePath,
                                      maskBase64: project.maskBase64,
                                      tile: tile,
                                    ),
                                  ),
                                );
                              } else if (value == 'compare') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ComparisonScreen(
                                      originalImagePath: project.originalImagePath,
                                      resultImageBase64: project.resultImageBase64,
                                    ),
                                  ),
                                );
                              } else if (value == 'delete') {
                                _deleteProject(project);
                              }
                            },
                          ),
                          onTap: () {
                            // Create tile object from project data
                            final tile = Tile(
                              id: project.tileId,
                              name: project.tileName,
                              imageUrl: '', // Not needed for viewing
                              size: project.tileSize,
                              price: project.tilePrice,
                            );
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultScreen(
                                  resultImageBase64: project.resultImageBase64,
                                  originalImagePath: project.originalImagePath,
                                  maskBase64: project.maskBase64,
                                  tile: tile,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

