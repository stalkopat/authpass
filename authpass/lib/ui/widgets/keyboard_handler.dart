import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_async_utils/flutter_async_utils.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

final _logger = Logger('keyboard_handler');

// Seems i can't figure out how to get `Shortcuts` & co to work.. workaround it for now
// also see https://github.com/flutter/flutter/issues/38076

//// very much copied from the example at
//// https://github.com/flutter/flutter/blob/master/dev/manual_tests/lib/actions.dart
//// not sure if i know what i'm doing.
//
//class KeyboardHandler extends StatelessWidget {
//  const KeyboardHandler({Key key, this.child}) : super(key: key);
//
//  final Widget child;
//
//  @override
//  Widget build(BuildContext context) {
//    return Shortcuts(
//      shortcuts: <LogicalKeySet, Intent>{
//        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const Intent(AuthpassIntents.searchKey),
//        LogicalKeySet(LogicalKeyboardKey.keyA): const Intent(AuthpassIntents.searchKey),
//      },
//      child: Actions(
//        actions: {
//          AuthpassIntents.searchKey: () => CallbackAction(AuthpassIntents.searchKey, onInvoke: (focusNode, _) {
//                _logger.info('search key action was invoked.');
//              }),
//        },
//        child: DefaultFocusTraversal(
//          policy: ReadingOrderTraversalPolicy(),
//          child: Shortcuts(
//            shortcuts: <LogicalKeySet, Intent>{
//              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
//                  const Intent(AuthpassIntents.searchKey),
//              LogicalKeySet(LogicalKeyboardKey.keyA): const Intent(AuthpassIntents.searchKey),
//              LogicalKeySet(LogicalKeyboardKey.tab): const Intent(AuthpassIntents.searchKey),
//            },
//            child: FocusScope(
//              autofocus: true,
//              child: child,
//            ),
//          ),
//        ),
//      ),
//    );
//  }
//}

class KeyboardHandler extends StatefulWidget {
  const KeyboardHandler({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  _KeyboardHandlerState createState() => _KeyboardHandlerState();
}

class _KeyboardHandlerState extends State<KeyboardHandler> {
  final _keyboardShortcutEvents = KeyboardShortcutEvents();

  final FocusNode _focusNode = FocusNode(
    debugLabel: 'AuthPassKeyboardFocus',
    onKey: (focusNode, rawKeyEvent) {
//      _logger.info('got onKey: ($focusNode) $rawKeyEvent');
      return true;
    },
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.info('didChange');
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _keyboardShortcutEvents,
      child: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: (key) {
          if (key is RawKeyDownEvent) {
//            final primaryFocus = WidgetsBinding.instance.focusManager.primaryFocus;
//            if (primaryFocus is FocusScopeNode) {
//              final focusedChild = primaryFocus.focusedChild;
//              _logger.info(
//                  '(me: ${_focusNode.hashCode}, ${_focusNode.hasFocus}, ${_focusNode.hasPrimaryFocus}) primaryFocus(${primaryFocus.hashCode}: ${primaryFocus.hasFocus}, ${primaryFocus.hasPrimaryFocus} /// (${focusedChild.hashCode}) ${focusedChild.hasFocus}, ${focusedChild.hasPrimaryFocus}');
//            } else {
//              _logger.info(
//                  '(me: ${_focusNode.hashCode}, ${_focusNode.hasFocus}, ${_focusNode.hasPrimaryFocus}) primaryFocus(${primaryFocus.hashCode}: ${primaryFocus.hasFocus}, ${primaryFocus.hasPrimaryFocus}');
//            }

            // for now do everything hard coded, until flutters actions & co get a bit easier to understand.. :-)
            final modifiers = key.data.modifiersPressed.keys;
            final character = key.logicalKey;
            _logger.info('RawKeyboardListener.onKey: $modifiers + $character ($key)');
            if (modifiers.length == 1 &&
                (modifiers.single == ModifierKey.controlModifier || modifiers.single == ModifierKey.metaModifier)) {
              final mapping = {
                LogicalKeyboardKey.keyF: const KeyboardShortcut(type: KeyboardShortcutType.search),
                LogicalKeyboardKey.keyB: const KeyboardShortcut(type: KeyboardShortcutType.copyUsername),
                LogicalKeyboardKey.keyC: const KeyboardShortcut(type: KeyboardShortcutType.copyPassword),
              };
              final shortcut = mapping[character];
              if (shortcut != null) {
                _keyboardShortcutEvents._shortcutEvents.add(shortcut);
              }
            } else if (modifiers.isEmpty) {
              if (character == LogicalKeyboardKey.tab) {
                WidgetsBinding.instance.focusManager.primaryFocus.nextFocus();
              }
            }
          }
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _keyboardShortcutEvents.dispose();
    super.dispose();
  }
}

enum KeyboardShortcutType {
  search,
  copyPassword,
  copyUsername,
}

class KeyboardShortcut {
  const KeyboardShortcut({@required this.type});
  final KeyboardShortcutType type;

  @override
  String toString() {
    return 'KeyboardShortcut{type: $type}';
  }
}

class KeyboardShortcutEvents with StreamSubscriberBase {
  KeyboardShortcutEvents() {
    handle(shortcutEvents.listen((event) {
      _logger.finer('Got keyboard event $event');
    }));
  }

  final StreamController<KeyboardShortcut> _shortcutEvents = StreamController<KeyboardShortcut>.broadcast();
  Stream<KeyboardShortcut> get shortcutEvents => _shortcutEvents.stream;

  void dispose() {
    _shortcutEvents.close();
    cancelSubscriptions();
  }
}
