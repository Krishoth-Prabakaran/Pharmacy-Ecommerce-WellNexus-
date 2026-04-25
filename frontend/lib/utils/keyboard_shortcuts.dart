// utils/keyboard_shortcuts.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget that enables keyboard shortcuts for form navigation
/// - Tab: Move to next field
/// - Shift+Tab: Move to previous field  
/// - Enter: Activate the primary button
class KeyboardShortcutHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEnter;
  final FocusNode? focusNode;

  const KeyboardShortcutHandler({
    Key? key,
    required this.child,
    this.onEnter,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKey: (node, event) {
        // Handle Enter key to activate button
        if (event.isKeyPressed(LogicalKeyboardKey.enter) && onEnter != null) {
          onEnter!();
          return KeyEventResult.handled;
        }
        // Tab and Shift+Tab are handled by default focus traversal
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Utility class for keyboard-friendly button configuration
class KeyboardButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final EdgeInsets? padding;

  const KeyboardButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  }) : super(key: key);

  @override
  State<KeyboardButton> createState() => _KeyboardButtonState();
}

class _KeyboardButtonState extends State<KeyboardButton> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.enter) && !widget.isLoading) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        if (event.isKeyPressed(LogicalKeyboardKey.space) && !widget.isLoading) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(
          border: _focusNode.hasFocus
              ? Border.all(color: Colors.blue, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton.icon(
          onPressed: widget.isLoading ? null : widget.onPressed,
          icon: widget.icon != null
              ? Icon(widget.icon)
              : const SizedBox.shrink(),
          label: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.label),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            padding: widget.padding,
            minimumSize: widget.width != null
                ? Size(widget.width!, 50)
                : const Size.fromHeight(50),
          ),
        ),
      ),
    );
  }
}

/// Utility to manage focus traversal between form fields
class FormFocusManager {
  final List<FocusNode> focusNodes = [];

  void add(FocusNode node) {
    focusNodes.add(node);
  }

  void moveToPrevious(FocusNode current) {
    final index = focusNodes.indexOf(current);
    if (index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  void moveToNext(FocusNode current) {
    final index = focusNodes.indexOf(current);
    if (index < focusNodes.length - 1) {
      focusNodes[index + 1].requestFocus();
    }
  }

  void dispose() {
    for (var node in focusNodes) {
      node.dispose();
    }
  }
}

/// Extension on TextEditingController for keyboard handling
extension KeyboardHandling on TextEditingController {
  /// Add keyboard listener for Tab/Shift+Tab navigation
  void addTabListener(FormFocusManager focusManager, FocusNode focusNode) {
    // This is handled by Flutter's default focus traversal
  }
}
