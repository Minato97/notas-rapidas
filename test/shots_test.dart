// SHOTS=1 flutter test test/shots_test.dart  -> store/screenshot_N.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notas_rapidas/logic.dart';
import 'package:notas_rapidas/main.dart';

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  final enabled = Platform.environment['SHOTS'] == '1';
  testWidgets('capturas', skip: !enabled, (tester) async {
    final sdk = Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
    final fonts = '$sdk/bin/cache/artifacts/material_fonts';
    await _font('Roboto', '$fonts/roboto-regular.ttf');
    await _font('Roboto', '$fonts/roboto-bold.ttf');
    await _font('MaterialIcons', '$fonts/materialicons-regular.otf');

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2160);
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    Note n(String id, String t, String b, int c, int mins, {bool pin = false}) =>
        Note(
          id: id,
          title: t,
          body: b,
          colorIndex: c,
          pinned: pin,
          updated: now.subtract(Duration(minutes: mins)),
        );
    final notes = [
      n('1', 'Lista del súper', '• Leche\n• Huevos\n• Pan integral\n• Manzanas\n• Café', 3, 5, pin: true),
      n('2', 'Ideas de regalo', 'Libro de cocina para mamá, audífonos para Luis, planta para la oficina.', 1, 90),
      n('3', 'Reunión del lunes', 'Revisar presupuesto, enviar reporte y agendar con el equipo de diseño.', 2, 300),
      n('4', 'Contraseña wifi visitas', 'Pedir a recepción el código nuevo.', 0, 1500),
      n('5', 'Viaje a la playa', 'Reservar hotel, comprar bloqueador, revisar el clima del fin de semana.', 5, 3000),
      n('6', 'Metas del mes', 'Leer 2 libros, correr 3 veces por semana, ahorrar el 10%.', 4, 6000),
    ];

    final key = GlobalKey();
    Future<void> save(String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.625);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('store/$name').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFFF59E0B),
          useMaterial3: true,
          fontFamily: 'Roboto',
            floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 0, focusElevation: 0, hoverElevation: 0, highlightElevation: 0),
        ),
        home: HomePage(initial: notes, persist: false),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await save('screenshot_1.png');

    await tester.enterText(find.byType(TextField), 'viaje');
    await tester.pump(const Duration(milliseconds: 300));
    await save('screenshot_2.png');

    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Ideas de regalo'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    await save('screenshot_3.png');

    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(GestureDetector).at(2));
    await tester.pump(const Duration(milliseconds: 300));
    await save('screenshot_4.png');
  });
}
