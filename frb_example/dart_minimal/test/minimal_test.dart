import 'dart:async';
import 'dart:isolate';

import 'package:frb_example_dart_minimal/src/rust/api/minimal.dart';
import 'package:frb_example_dart_minimal/src/rust/frb_generated.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('killing isolate lock mutex undefinitely', () async {
    Future<void> keepRunning(SendPort port) async {
      await RustLib.init();
      await runWithLock(f: () async {
        for (;;) {
          print('Running...');
          port.send(Step.running);
          await Future<void>.delayed(Duration(seconds: 1));
        }
      });
    }

    Future<void> finish(SendPort port) async {
      await RustLib.init();
      await runWithLock(f: () {
        port.send(Step.finished);
        print('Finished');
      });
    }

    var current = Step.idle;
    final port = ReceivePort();
    port.listen((msg) {
      current = msg as Step;
    });
    final completed = ReceivePort();
    completed.listen((msg) {
      print('last msg: $msg');
      current = Step.runnerKilled;
    });

    final runner = await Isolate.spawn(
      keepRunning,
      port.sendPort,
      onError: completed.sendPort,
      onExit: completed.sendPort,
      debugName: 'runner',
    );

    while (current != Step.running) {
      print('Waiting for runner...');
      await Future<void>.delayed(Duration(milliseconds: 500));
    }

    runner.kill();
    print('Runner killed');

    while (current != Step.runnerKilled) {
      print('Waiting for runner to die...');
      await Future<void>.delayed(Duration(milliseconds: 500));
    }

    // it will hang undefinitely
    await finish(port.sendPort);

    // it never reaches this point
    expect(current, Step.finished);
  });
}

enum Step {
  idle,
  running,
  runnerKilled,
  finished,
}
