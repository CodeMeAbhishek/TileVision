import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class ProjectService {
  static const String _projectsFileName = 'tilevision_projects.json';

  /// Save a project to local storage
  static Future<void> saveProject(Project project) async {
    try {
      final projects = await loadProjects();
      projects.add(project);
      await _saveProjects(projects);
    } catch (e) {
      throw Exception('Failed to save project: $e');
    }
  }

  /// Load all saved projects
  static Future<List<Project>> loadProjects() async {
    try {
      final file = await _getProjectsFile();
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) => Project.fromJson(json)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
    } catch (e) {
      return [];
    }
  }

  /// Delete a project
  static Future<void> deleteProject(String projectId) async {
    try {
      final projects = await loadProjects();
      projects.removeWhere((p) => p.id == projectId);
      await _saveProjects(projects);
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  /// Clear all projects
  static Future<void> clearAllProjects() async {
    try {
      final file = await _getProjectsFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to clear projects: $e');
    }
  }

  /// Get project by ID
  static Future<Project?> getProject(String projectId) async {
    final projects = await loadProjects();
    try {
      return projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> _saveProjects(List<Project> projects) async {
    final file = await _getProjectsFile();
    final jsonList = projects.map((p) => p.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  static Future<File> _getProjectsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_projectsFileName');
  }
}

