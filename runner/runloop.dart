import 'dart:ffi';
import 'dart:math' show min, max;

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'timepoint.dart';

class RunLoop {
  void Run() {
    var keep_running = true;
    var next_flutter_event_time = TimePoint().now;

    while (keep_running) {
      MsgWaitForMultipleObjects(0, nullptr, FALSE, 0, QS_ALLINPUT);
      bool processed_events = false;

      final message = MSG.allocate();
      while (PeekMessage(message.addressOf, NULL, 0, 0, PM_REMOVE) == TRUE) {
        processed_events = true;
        if (message.message == WM_QUIT) {
          keep_running = false;
          break;
        }

        TranslateMessage(message.addressOf);
        DispatchMessage(message.addressOf);
      }

      if (!processed_events) {
        next_flutter_event_time =
            min(next_flutter_event_time, ProcessFlutterMessages());
      }
    }
  }

  int ProcessFlutterMessages() {
    return 0;
  }
}
