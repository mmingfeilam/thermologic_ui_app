// Create this as: lib/services/search_highlighter_service.dart

import 'package:flutter/material.dart';

class SearchHighlighterService {
  // Configurable highlighting styles
  static const Color defaultHighlightColor = Color(0xFFFFEB3B); // Yellow
  static const Color defaultTextColor = Colors.black87;
  static const FontWeight defaultFontWeight = FontWeight.bold;

  // Alternative highlight themes for different contexts
  static const Map<String, Map<String, dynamic>> highlightThemes = {
    'default': {
      'backgroundColor': Color(0xFFFFEB3B),
      'textColor': Colors.black87,
      'fontWeight': FontWeight.bold,
    },
    'subtle': {
      'backgroundColor': Color(0xFFF5F5F5),
      'textColor': Color(0xFF1E3A8A),
      'fontWeight': FontWeight.w600,
    },
    'accent': {
      'backgroundColor': Color(0xFF1E3A8A),
      'textColor': Colors.white,
      'fontWeight': FontWeight.bold,
    },
    'success': {
      'backgroundColor': Color(0xFFE8F5E8),
      'textColor': Color(0xFF2E7D2E),
      'fontWeight': FontWeight.w500,
    },
  };

  /// Extract meaningful search terms from a query string
  /// Filters out common words and handles special characters
  static List<String> extractQueryTerms(
    String query, {
    int minTermLength = 2,
    bool includePunctuation = false,
    List<String> stopWords = const [
      'the',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by'
    ],
  }) {
    if (query.isEmpty) return [];

    // Handle quoted phrases first
    List<String> terms = [];
    String processedQuery = query;

    // Extract quoted phrases
    RegExp quotedPhrases = RegExp(r'"([^"]*)"');
    for (Match match in quotedPhrases.allMatches(query)) {
      String phrase = match.group(1)?.trim() ?? '';
      if (phrase.length >= minTermLength) {
        terms.add(phrase.toLowerCase());
      }
      processedQuery = processedQuery.replaceAll(match.group(0)!, ' ');
    }

    // Process remaining words
    List<String> words = processedQuery
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((term) => includePunctuation
            ? term.trim()
            : term.replaceAll(RegExp(r'[^\w]'), '').trim())
        .where((term) =>
            term.length >= minTermLength &&
            !stopWords.contains(term.toLowerCase()))
        .toList();

    terms.addAll(words);

    // Remove duplicates while preserving order
    return terms.toSet().toList();
  }

  /// Create highlighted TextSpan from content and query terms
  static TextSpan highlightText(
    String content,
    List<String> queryTerms, {
    String theme = 'default',
    TextStyle? baseStyle,
    bool caseSensitive = false,
  }) {
    if (queryTerms.isEmpty || content.isEmpty) {
      return TextSpan(
        text: content,
        style: baseStyle,
      );
    }

    // Get theme styles
    final themeConfig = highlightThemes[theme] ?? highlightThemes['default']!;
    final highlightStyle = TextStyle(
      backgroundColor: themeConfig['backgroundColor'],
      color: themeConfig['textColor'],
      fontWeight: themeConfig['fontWeight'],
    );

    List<TextSpan> spans = [];
    String remainingContent = content;
    int currentIndex = 0;

    // Create regex pattern for all query terms
    String pattern = queryTerms.map((term) => RegExp.escape(term)).join('|');

    RegExp regex = RegExp(
      '($pattern)',
      caseSensitive: caseSensitive,
    );

    // Find all matches and create spans
    for (Match match in regex.allMatches(content)) {
      // Add text before the match
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: content.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }

      // Add the highlighted match
      spans.add(TextSpan(
        text: match.group(0)!,
        style: baseStyle?.copyWith(
              backgroundColor: themeConfig['backgroundColor'],
              color: themeConfig['textColor'],
              fontWeight: themeConfig['fontWeight'],
            ) ??
            highlightStyle,
      ));

      currentIndex = match.end;
    }

    // Add remaining text after the last match
    if (currentIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  /// Extract smart snippet around search matches
  static String extractSmartSnippet(
    String content,
    List<String> queryTerms, {
    int maxLength = 200,
    String ellipsis = '...',
    bool prioritizeFirstMatch = true,
  }) {
    if (content.length <= maxLength) {
      return content;
    }

    if (queryTerms.isEmpty) {
      return '${content.substring(0, maxLength)}$ellipsis';
    }

    String contentLower = content.toLowerCase();
    List<int> matchPositions = [];

    // Find all match positions
    for (String term in queryTerms) {
      String termLower = term.toLowerCase();
      int index = 0;
      while ((index = contentLower.indexOf(termLower, index)) != -1) {
        matchPositions.add(index);
        index += termLower.length;
      }
    }

    if (matchPositions.isEmpty) {
      return '${content.substring(0, maxLength)}$ellipsis';
    }

    matchPositions.sort();

    // Choose optimal position for snippet
    int targetPosition;
    if (prioritizeFirstMatch) {
      targetPosition = matchPositions.first;
    } else {
      // Find position with most matches nearby
      targetPosition = _findOptimalSnippetPosition(matchPositions, maxLength);
    }

    // Calculate snippet bounds
    int snippetStart =
        (targetPosition - (maxLength ~/ 2)).clamp(0, content.length);
    int snippetEnd = (snippetStart + maxLength).clamp(0, content.length);

    // Adjust to maximize content
    if (snippetEnd - snippetStart < maxLength && snippetStart > 0) {
      snippetStart = (snippetEnd - maxLength).clamp(0, content.length);
    }

    // Try to break at word boundaries
    snippetStart = _adjustToWordBoundary(content, snippetStart, forward: true);
    snippetEnd = _adjustToWordBoundary(content, snippetEnd, forward: false);

    String snippet = content.substring(snippetStart, snippetEnd);

    // Add ellipsis
    String result = '';
    if (snippetStart > 0) result += ellipsis;
    result += snippet;
    if (snippetEnd < content.length) result += ellipsis;

    return result;
  }

  /// Count total matches of query terms in content
  static int countMatches(
    String content,
    List<String> queryTerms, {
    bool caseSensitive = false,
  }) {
    if (queryTerms.isEmpty || content.isEmpty) return 0;

    int totalMatches = 0;
    String searchContent = caseSensitive ? content : content.toLowerCase();

    for (String term in queryTerms) {
      String searchTerm = caseSensitive ? term : term.toLowerCase();
      int index = 0;
      while ((index = searchContent.indexOf(searchTerm, index)) != -1) {
        totalMatches++;
        index += searchTerm.length;
      }
    }

    return totalMatches;
  }

  /// Get match statistics for a piece of content
  static Map<String, dynamic> getMatchStats(
    String content,
    List<String> queryTerms, {
    bool caseSensitive = false,
  }) {
    Map<String, int> termMatches = {};
    int totalMatches = 0;
    List<int> matchPositions = [];

    String searchContent = caseSensitive ? content : content.toLowerCase();

    for (String term in queryTerms) {
      String searchTerm = caseSensitive ? term : term.toLowerCase();
      int termCount = 0;
      int index = 0;

      while ((index = searchContent.indexOf(searchTerm, index)) != -1) {
        termCount++;
        totalMatches++;
        matchPositions.add(index);
        index += searchTerm.length;
      }

      if (termCount > 0) {
        termMatches[term] = termCount;
      }
    }

    return {
      'totalMatches': totalMatches,
      'termMatches': termMatches,
      'matchedTerms': termMatches.keys.toList(),
      'matchPositions': matchPositions,
      'coverage':
          queryTerms.isEmpty ? 0.0 : termMatches.length / queryTerms.length,
    };
  }

  /// Create a highlighted widget with match information
  static Widget buildHighlightedContent(
    String content,
    List<String> queryTerms, {
    String theme = 'default',
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
    bool showMatchCount = false,
    VoidCallback? onTap,
  }) {
    final matchStats = getMatchStats(content, queryTerms);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match count indicator
        if (showMatchCount && matchStats['totalMatches'] > 0)
          Container(
            margin: EdgeInsets.only(bottom: 4),
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 12, color: Colors.blue.shade600),
                SizedBox(width: 4),
                Text(
                  '${matchStats['totalMatches']} match${matchStats['totalMatches'] > 1 ? 'es' : ''}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Highlighted content
        GestureDetector(
          onTap: onTap,
          child: RichText(
            text: highlightText(content, queryTerms,
                theme: theme, baseStyle: style),
            maxLines: maxLines,
            overflow: overflow ?? TextOverflow.clip,
          ),
        ),
      ],
    );
  }

  // Private helper methods
  static int _findOptimalSnippetPosition(List<int> positions, int windowSize) {
    if (positions.length <= 1) return positions.first;

    int bestPosition = positions.first;
    int maxDensity = 0;

    for (int i = 0; i < positions.length; i++) {
      int currentPos = positions[i];
      int density = 0;

      for (int j = 0; j < positions.length; j++) {
        if ((positions[j] - currentPos).abs() <= windowSize ~/ 2) {
          density++;
        }
      }

      if (density > maxDensity) {
        maxDensity = density;
        bestPosition = currentPos;
      }
    }

    return bestPosition;
  }

  static int _adjustToWordBoundary(String content, int position,
      {required bool forward}) {
    if (position <= 0 || position >= content.length) return position;

    if (forward) {
      // Move forward to next word boundary
      while (position < content.length && !_isWordBoundary(content, position)) {
        position++;
      }
    } else {
      // Move backward to previous word boundary
      while (position > 0 && !_isWordBoundary(content, position)) {
        position--;
      }
    }

    return position.clamp(0, content.length);
  }

  static bool _isWordBoundary(String content, int position) {
    if (position <= 0 || position >= content.length) return true;

    String current = content[position];
    String previous = content[position - 1];

    return RegExp(r'\s').hasMatch(current) ||
        RegExp(r'\s').hasMatch(previous) ||
        RegExp(r'[.!?;,]').hasMatch(previous);
  }
}
