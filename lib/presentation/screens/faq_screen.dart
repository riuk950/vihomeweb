import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                  theme.colorScheme.secondary.withValues(alpha: 0.6),
                  theme.colorScheme.tertiary.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Preguntas Frecuentes',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Content
                    Expanded(
                      child: FutureBuilder<String>(
                        future: rootBundle.loadString(
                          'preguntas_frecuentes.md',
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error al cargar las preguntas frecuentes',
                              ),
                            );
                          }
                          return Markdown(
                            data: snapshot.data ?? '',
                            selectable: true,
                            padding: const EdgeInsets.all(32),
                            styleSheet: MarkdownStyleSheet(
                              h1: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              h2: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                height: 2.0,
                              ),
                              h3: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                              p: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                              ),
                              listBullet: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
