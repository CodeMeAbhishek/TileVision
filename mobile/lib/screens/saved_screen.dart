import 'package:flutter/material.dart';
import '../helpers/responsive_helper.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  // TODO: Replace with actual saved items from Supabase or local storage
  List<Map<String, dynamic>> _savedItems = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = ResponsiveHelper.getPadding(context);
    final spacing = ResponsiveHelper.getSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        automaticallyImplyLeading: false,
      ),
      body: _savedItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: spacing * 2),
                  Text(
                    'No Saved Items',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: spacing),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding.left * 2),
                    child: Text(
                      'Save your favorite tiles and projects here for quick access',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // TODO: Reload saved items
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: padding,
                itemCount: _savedItems.length,
                itemBuilder: (context, index) {
                  final item = _savedItems[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: spacing),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: item['image'] != null
                              ? Image.memory(item['image'])
                              : Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey.shade400,
                                ),
                        ),
                      ),
                      title: Text(
                        item['title'] ?? 'Untitled',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        item['subtitle'] ?? '',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.bookmark, color: Colors.orange),
                        onPressed: () {
                          // TODO: Remove from saved
                          setState(() {
                            _savedItems.removeAt(index);
                          });
                        },
                      ),
                      onTap: () {
                        // TODO: Navigate to item details
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

