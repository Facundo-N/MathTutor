// lib/models/tutorial_scene_model.dart
import 'package:flutter/material.dart';

// ─── ACCIÓN DEL CONEJO BANNY POR ESCENA ────────────────────────────────────
enum BunnyAction {
  none,
  greet,        // llama greet() → brazo saluda
  startTalking, // isSpeaking = true → boca anima
  stopTalking,  // isSpeaking = false
  magicFlip,    // llama doMagicFlip() → giro 3D
  celebrate,    // greet() + isSpeaking = true
}

// ─── TIPO DE BLOQUE MATEMÁTICO ──────────────────────────────────────────────
enum MathBlockType {
  blockGreen,   // #145C2B + borde #2DA94F
  blockDark,    // #161A24 + borde #272C3B
  blockGreenGlow, // blockGreen + shadow verde brillante
  blockGreenGhost, // blockGreen + opacidad (efecto fantasma)
  blockGreenMoving, // blockGreen + animación lateral
  operator,     // "=" blanco, sin contenedor
  fraction,     // columna: numerador / divisor / denominador
  blockBracket, // Paréntesis visual
  blockAction,  // Operación intermedia (naranja)
  blockRoot,    // Raíz cuadrada o cúbica entrante (amarillo)
}

// ─── BLOQUE INDIVIDUAL DE LA ECUACIÓN ───────────────────────────────────────
class MathBlock {
  final String id;
  final String value;
  final MathBlockType type;
  /// Solo para type == fraction: numerador y denominador.
  final String? fractionNumerator;
  final String? fractionDenominator;

  const MathBlock({
    required this.id,
    required this.value,
    required this.type,
    this.fractionNumerator,
    this.fractionDenominator,
  });
}

// ─── MathBlock factories convenientes ───────────────────────────────────────
class MB {
  static MathBlock green(String v, {String? id}) => MathBlock(id: id ?? v, value: v, type: MathBlockType.blockGreen);
  static MathBlock dark(String v, {String? id}) => MathBlock(id: id ?? v, value: v, type: MathBlockType.blockDark);
  static MathBlock glow(String v, {String? id}) => MathBlock(id: id ?? v, value: v, type: MathBlockType.blockGreenGlow);
  static MathBlock ghost(String v, {String? id}) => MathBlock(id: id ?? v, value: v, type: MathBlockType.blockGreenGhost);
  static MathBlock moving(String v, {String? id}) => MathBlock(id: id ?? v, value: v, type: MathBlockType.blockGreenMoving);
  static MathBlock eq({String? id}) => MathBlock(id: id ?? '=', value: '=', type: MathBlockType.operator);
  static MathBlock bracket(String v, {String? id}) => MathBlock(id: id ?? v, value: v, type: MathBlockType.blockBracket);
  static MathBlock action(String v, {String? id}) => MathBlock(id: id ?? v, value: v, type: MathBlockType.blockAction);
  static MathBlock root(String v, {String? id}) => MathBlock(id: id ?? v, value: v, type: MathBlockType.blockRoot);
  static MathBlock frac(String n, String d, {String? id}) => MathBlock(
    id: id ?? '$n/$d',
    value: '$n/$d',
    type: MathBlockType.fraction,
    fractionNumerator: n,
    fractionDenominator: d,
  );
}

// ─── ESCENA DEL TUTORIAL ───────────────────────────────────────────────────
class TutorialScene {
  /// Texto mostrado en el reloj, ej. "0:04"
  final String time;

  /// Subtítulo (texto amarillo inferior)
  final String subtitle;

  /// Texto dentro de la burbuja del conejo
  final String speechBubble;

  /// Acción que Banny ejecuta al inicio de la escena
  final BunnyAction bunnyAction;

  /// Posición de Banny dentro del Stack del reproductor.
  /// Usa Alignment: Alignment(dx, dy) donde -1/-1 es arriba-izquierda, 1/1 es abajo-derecha.
  final Alignment bunnyAlignment;

  /// Tamaño visual de Banny en esta escena.
  final double bunnySize;

  /// Lista de bloques que forman la ecuación en pantalla.
  final List<MathBlock> mathBlocks;

  /// Duración de la escena antes de pasar a la siguiente.
  final Duration duration;
  final String? interactiveTargetId;
  final String? errorFeedback;

  const TutorialScene({
    required this.time,
    required this.subtitle,
    required this.speechBubble,
    required this.bunnyAction,
    required this.bunnyAlignment,
    this.bunnySize = 220.0,
    required this.mathBlocks,
    this.duration = const Duration(milliseconds: 4500),
    this.interactiveTargetId,
    this.errorFeedback,
  });
}

// ─── GUIÓN COMPLETO: 2x + 4 = 5 ────────────────────────────────────────────
final List<TutorialScene> linearTutorialScenes = [
  // Escena 0: Intro
  TutorialScene(
    time: '0:04',
    subtitle: '¡Hola! Soy Banny. Seré tu guía para enseñarte a resolver ecuaciones.',
    speechBubble: 'Resolver Ecuaciones',
    bunnyAction: BunnyAction.greet,
    bunnyAlignment: const Alignment(0.0, 0.0),
    bunnySize: 420.0,
    mathBlocks: [],
    duration: const Duration(milliseconds: 6000),
  ),

  // Escena 1: Objetivo
  TutorialScene(
    time: '0:08',
    subtitle: "Tu objetivo principal es despejar la ecuación: dejar a la 'x' sola.",
    speechBubble: 'Despejar la X',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.green('a', id: 'a'), MB.dark('x', id: 'x'), MB.green('+b', id: 'b'), MB.eq(id: 'eq'), MB.green('d', id: 'd'),
    ],
    duration: const Duration(milliseconds: 6000),
  ),

  // Escena 2: Mover Banny hacia el +b (desde abajo)
  TutorialScene(
    time: '0:12',
    subtitle: "Para ello, comenzamos moviendo los términos independientes, como el '+b'.",
    speechBubble: 'Agrupar términos',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.green('a', id: 'a'), MB.dark('x', id: 'x'), MB.green('+b', id: 'b'), MB.eq(id: 'eq'), MB.green('d', id: 'd'),
    ],
    duration: const Duration(milliseconds: 5000),
  ),

  // Escena 2.5: Selección Fantasma (pausa)
  TutorialScene(
    time: '0:15',
    subtitle: "Seleccionamos el '+b' y nos preparamos para moverlo...",
    speechBubble: 'Seleccionar bloque',
    bunnyAction: BunnyAction.none,
    bunnyAlignment: const Alignment(-0.8, 0.8), // Banny se queda quieto
    mathBlocks: [
      MB.green('a', id: 'a'), MB.dark('x', id: 'x'), MB.ghost('+b', id: 'b'), MB.eq(id: 'eq'), MB.green('d', id: 'd'),
    ],
    duration: const Duration(milliseconds: 5000),
    interactiveTargetId: 'b',
    errorFeedback: '¡Esa no! Arrastra el término independiente (+b) hacia el otro lado.',
  ),

  // Escena 3: Mover +b
  TutorialScene(
    time: '0:18',
    subtitle: "Lo trasladamos al lado derecho de la ecuación.",
    speechBubble: 'Mover al lado opuesto',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.green('a', id: 'a'), MB.dark('x', id: 'x'), MB.eq(id: 'eq'), MB.green('d', id: 'd'), MB.green('+b', id: 'b'),
    ],
    duration: const Duration(milliseconds: 6000),
  ),

  // Escena 4: Magia (cruza y cambia signo)
  TutorialScene(
    time: '0:22',
    subtitle: "Al cruzar el signo '=', la operación se invierte. Pasa como '-b'.",
    speechBubble: 'Invertir Operación',
    bunnyAction: BunnyAction.magicFlip,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.green('a', id: 'a'), MB.dark('x', id: 'x'), MB.eq(id: 'eq'), MB.green('d', id: 'd'), MB.green('-b', id: 'b'),
    ],
    duration: const Duration(milliseconds: 6500),
  ),

  // Escena 5: Mover Banny hacia 'a'
  TutorialScene(
    time: '0:26',
    subtitle: "Finalmente, vemos que la letra 'a' está multiplicando a nuestra 'x'.",
    speechBubble: 'Resolver y Dividir',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.green('a', id: 'a'), MB.dark('x', id: 'x'), MB.eq(id: 'eq'), MB.green('d-b', id: 'd'),
    ],
    duration: const Duration(milliseconds: 5000),
  ),

  // Escena 5.5: Selección Fantasma de 'a'
  TutorialScene(
    time: '0:29',
    subtitle: "La seleccionamos también para moverla...",
    speechBubble: 'Seleccionar factor',
    bunnyAction: BunnyAction.none,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.ghost('a', id: 'a'), MB.dark('x', id: 'x'), MB.eq(id: 'eq'), MB.green('d-b', id: 'd'),
    ],
    duration: const Duration(milliseconds: 5000),
    interactiveTargetId: 'a',
    errorFeedback: 'Fío fío... ¡Arrastra el coeficiente (a) para dividir!',
  ),

  // Escena 5.7: Mover 'a' al otro lado
  TutorialScene(
    time: '0:32',
    subtitle: "Trasladamos la 'a' al lado derecho.",
    speechBubble: 'Mover al otro lado',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.dark('x', id: 'x'), MB.eq(id: 'eq'), MB.green('d-b', id: 'd'), MB.green('a', id: 'a'),
    ],
    duration: const Duration(milliseconds: 5500),
  ),

  // Escena 6: Fracción
  TutorialScene(
    time: '0:35',
    subtitle: "Al estar multiplicando, la operación se invierte y 'a' pasa a dividir.",
    speechBubble: 'Formar la Fracción',
    bunnyAction: BunnyAction.stopTalking,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.dark('x', id: 'x'), MB.eq(id: 'eq'), MB.frac('d-b', 'a', id: 'frac'),
    ],
    duration: const Duration(milliseconds: 6000),
  ),

  // Escena 7: Victoria
  TutorialScene(
    time: '0:39',
    subtitle: "¡La ecuación está resuelta!  x = (d-b)/a. ¡Ahora es tu turno de practicar!",
    speechBubble: '¡Comienza a jugar!',
    bunnyAction: BunnyAction.celebrate,
    bunnyAlignment: const Alignment(0.0, 0.8), // Al centro y abajo
    mathBlocks: [
      MB.dark('x', id: 'x'), MB.eq(id: 'eq'), MB.frac('d-b', 'a', id: 'frac'),
    ],
    duration: const Duration(milliseconds: 6500),
  ),
]; // Fin de linearTutorialScenes

// ─── GUIÓN COMPLETO: 3(x+2) = 15 (Propiedad Distributiva) ──────────────────
final List<TutorialScene> distributiveTutorialScenes = [
  TutorialScene(
    time: '0:00',
    subtitle: "¡Aprenderemos sobre paréntesis y la Propiedad Distributiva!",
    speechBubble: '¡Hola ninja!',
    bunnyAction: BunnyAction.greet,
    bunnyAlignment: const Alignment(0.0, 0.0),
    bunnySize: 420.0,
    mathBlocks: [],
    duration: const Duration(milliseconds: 5000),
  ),
  TutorialScene(
    time: '0:03',
    subtitle: "Observa la ecuación. Tenemos un número multiplicando al paréntesis.",
    speechBubble: 'Analiza',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.green('3', id: '3'), MB.bracket('(', id: 'b1'), MB.dark('x', id: 'x'), MB.dark('+2', id: '2'), MB.bracket(')', id: 'b2'), MB.eq(id: 'eq'), MB.green('15', id: '15'),
    ],
    duration: const Duration(milliseconds: 6000),
  ),
  TutorialScene(
    time: '0:07',
    subtitle: "El 3 multiplicará a TODOS los elementos dentro del paréntesis.",
    speechBubble: 'Distribuye',
    bunnyAction: BunnyAction.none,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.glow('3', id: '3'), MB.bracket('(', id: 'b1'), MB.dark('x', id: 'x'), MB.dark('+2', id: '2'), MB.bracket(')', id: 'b2'), MB.eq(id: 'eq'), MB.green('15', id: '15'),
    ],
    duration: const Duration(milliseconds: 5000),
    interactiveTargetId: '3',
    errorFeedback: '¡Arrastra el número 3 hacia el paréntesis para distribuirlo!',
  ),
  TutorialScene(
    time: '0:10',
    subtitle: "Se reparte: multiplicamos 3 por x, y 3 por +2.",
    speechBubble: '¡Multiplica!',
    bunnyAction: BunnyAction.magicFlip,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.action('3·x', id: '3'), MB.action('+', id: 'plus'), MB.action('3·2', id: '2'), MB.eq(id: 'eq'), MB.green('15', id: '15'),
    ],
    duration: const Duration(milliseconds: 6000),
  ),
  TutorialScene(
    time: '0:14',
    subtitle: "Al resolver las multiplicaciones (3x y 6) ya no hay paréntesis.",
    speechBubble: 'Ecuación Simple',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.dark('3x', id: '3'), MB.green('+6', id: '2'), MB.eq(id: 'eq'), MB.green('15', id: '15'),
    ],
    duration: const Duration(milliseconds: 5500),
    interactiveTargetId: '2',
    errorFeedback: '¡Arrastra el +6 hacia el otro lado!',
  ),
  TutorialScene(
    time: '0:17',
    subtitle: "El +6 cruza pasando por el signo igual y cambia a -6.",
    speechBubble: 'Cambio de Signo',
    bunnyAction: BunnyAction.magicFlip,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.dark('3x', id: '3'), MB.eq(id: 'eq'), MB.green('15', id: '15'), MB.green('-6', id: '2'),
    ],
    duration: const Duration(milliseconds: 5000),
  ),
  TutorialScene(
    time: '0:20',
    subtitle: "Resolvemos: 15 menos 6 es 9.",
    speechBubble: 'Resta',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.dark('3x', id: '3'), MB.eq(id: 'eq'), MB.green('9', id: '15'),
    ],
    duration: const Duration(milliseconds: 4500),
    interactiveTargetId: '3',
    errorFeedback: '¡Arrastra el número 3 para dividir y despejar la x!',
  ),
  TutorialScene(
    time: '0:24',
    subtitle: "El 3 que multiplica pasa a dividir al otro lado.",
    speechBubble: 'A Dividir',
    bunnyAction: BunnyAction.none,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.dark('x', id: '3'), MB.eq(id: 'eq'), MB.frac('9', '3', id: 'frac'),
    ],
    duration: const Duration(milliseconds: 5000),
  ),
  TutorialScene(
    time: '0:27',
    subtitle: "9 entre 3 da 3. ¡Terminaste de resolverla!",
    speechBubble: '¡Victoria Ninja!',
    bunnyAction: BunnyAction.celebrate,
    bunnyAlignment: const Alignment(0.0, 0.8),
    mathBlocks: [
      MB.dark('x', id: '3'), MB.eq(id: 'eq'), MB.green('3', id: 'frac'),
    ],
    duration: const Duration(milliseconds: 6500),
  ),
];

// ─── GUIÓN COMPLETO: x² - 3x = 0 (Factorización) ───────────────────────────
final List<TutorialScene> factorizationTutorialScenes = [
  TutorialScene(
    time: '0:00',
    subtitle: "¡Aprenderemos a factorizar y dominar polinomios!",
    speechBubble: 'Sacar el lego común',
    bunnyAction: BunnyAction.greet,
    bunnyAlignment: const Alignment(0.0, 0.0),
    bunnySize: 420.0,
    mathBlocks: [],
    duration: const Duration(milliseconds: 5000),
  ),
  TutorialScene(
    time: '0:03',
    subtitle: "Busquemos qué piezas tienen en común estos términos.",
    speechBubble: 'Factorización',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.dark('x²', id: 'x2'), MB.green('-3x', id: '3x'), MB.eq(id: 'eq'), MB.green('0', id: '0'),
    ],
    duration: const Duration(milliseconds: 6000),
  ),
  TutorialScene(
    time: '0:07',
    subtitle: "Tanto la x² como el 3x comparten una 'x'. ¡Vamos a extraerla!",
    speechBubble: 'Factor Común',
    bunnyAction: BunnyAction.none,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.glow('x²', id: 'x2'), MB.glow('-3x', id: '3x'), MB.eq(id: 'eq'), MB.green('0', id: '0'),
    ],
    duration: const Duration(milliseconds: 5000),
    interactiveTargetId: 'x2',
    errorFeedback: '¡Arrastra una de las x para sacarla como factor común!',
  ),
  TutorialScene(
    time: '0:10',
    subtitle: "La 'x' común sale del grupo hacia la izquierda como un factor independiente.",
    speechBubble: '¡Hacia afuera!',
    bunnyAction: BunnyAction.magicFlip,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.action('x', id: 'xout'), MB.bracket('(', id: 'b1'), MB.dark('x', id: 'x2'), MB.dark('-3', id: '3x'), MB.bracket(')', id: 'b2'), MB.eq(id: 'eq'), MB.green('0', id: '0'),
    ],
    duration: const Duration(milliseconds: 6000),
  ),
  TutorialScene(
    time: '0:14',
    subtitle: "Hemos convertido la suma en dos factores multiplicados que dan 0.",
    speechBubble: 'Regla del Cero',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.dark('x', id: 'xout'), MB.bracket('(', id: 'b1'), MB.dark('x-3', id: 'x2'), MB.bracket(')', id: 'b2'), MB.eq(id: 'eq'), MB.green('0', id: '0'),
    ],
    duration: const Duration(milliseconds: 5500),
  ),
  TutorialScene(
    time: '0:17',
    subtitle: "Esto significa que UNO de los factores debe ser cero. Ya tenemos x=0. Resolvamos el otro.",
    speechBubble: '¡Dos Caminos!',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(0.0, 0.8),
    mathBlocks: [
      MB.action('x = 0', id: 'xout'), MB.dark('   ó   ', id: 'o'), MB.dark('x - 3 = 0', id: 'x2_comp'),
    ],
    duration: const Duration(milliseconds: 6000),
  ),
  TutorialScene(
    time: '0:22',
    subtitle: "Para el segundo camino: x - 3 = 0. Despejemos la x.",
    speechBubble: 'Despejar',
    bunnyAction: BunnyAction.none,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.dark('x', id: 'x2_comp_x'), MB.green('-3', id: 'x2_comp_3'), MB.eq(id: 'x2_comp_eq'), MB.green('0', id: 'x2_comp_0'),
    ],
    duration: const Duration(milliseconds: 4500),
    interactiveTargetId: 'x2_comp_3',
    errorFeedback: '¡Arrastra el -3 hacia el otro lado para despejar la x!',
  ),
  TutorialScene(
    time: '0:25',
    subtitle: "El -3 cruza hacia la derecha como positivo (+3).",
    speechBubble: '+3',
    bunnyAction: BunnyAction.magicFlip,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.dark('x', id: 'x2_comp_x'), MB.eq(id: 'x2_comp_eq'), MB.green('0', id: 'x2_comp_0'), MB.green('+3', id: 'x2_comp_3'),
    ],
    duration: const Duration(milliseconds: 5000),
  ),
  TutorialScene(
    time: '0:28',
    subtitle: "¡Tenemos nuestra segunda respuesta validada: x = 3!",
    speechBubble: '¡Resuelto!',
    bunnyAction: BunnyAction.celebrate,
    bunnyAlignment: const Alignment(0.0, 0.8),
    mathBlocks: [
      MB.action('x = 0', id: 'final_0'), MB.dark('   y   ', id: 'y'), MB.action('x = 3', id: 'final_3'),
    ],
    duration: const Duration(milliseconds: 6500),
  ),
];

// ─── GUIÓN COMPLETO: x² - 9 = 0 (Ecuación Cuadrática) ──────────────────────
final List<TutorialScene> quadraticTutorialScenes = [
  TutorialScene(
    time: '0:00',
    subtitle: "El exponente ² significa que un número se multiplicó por sí mismo.",
    speechBubble: 'Potencias',
    bunnyAction: BunnyAction.greet,
    bunnyAlignment: const Alignment(0.0, 0.0),
    bunnySize: 420.0,
    mathBlocks: [],
    duration: const Duration(milliseconds: 5000),
  ),
  TutorialScene(
    time: '0:03',
    subtitle: "Primero, aplica los fundamentos que conoces y despeja la x².",
    speechBubble: 'Despejar base',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.dark('x²', id: 'x2'), MB.green('-9', id: '9'), MB.eq(id: 'eq'), MB.green('0', id: '0'),
    ],
    duration: const Duration(milliseconds: 5500),
    interactiveTargetId: '9',
    errorFeedback: '¡Arrastra el -9 hacia el otro lado!',
  ),
  TutorialScene(
    time: '0:06',
    subtitle: "Mueves el -9 sumando al lado derecho.",
    speechBubble: '+9',
    bunnyAction: BunnyAction.none,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.dark('x²', id: 'x2'), MB.eq(id: 'eq'), MB.green('0', id: '0'), MB.green('+9', id: '9'),
    ],
    duration: const Duration(milliseconds: 5000),
  ),
  TutorialScene(
    time: '0:09',
    subtitle: "¡Perfecto! x² = 9. Ahora la 'x' está casi libre.",
    speechBubble: 'Casi lista',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.dark('x²', id: 'x2'), MB.eq(id: 'eq'), MB.green('9', id: '0'),
    ],
    duration: const Duration(milliseconds: 5000),
  ),
  TutorialScene(
    time: '0:12',
    subtitle: "Para destruir la potencia de 2, la envolvemos en su antídoto: la Raíz Cuadrada (√).",
    speechBubble: 'Súper Raíz',
    bunnyAction: BunnyAction.magicFlip,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.root('√', id: 'rL'), MB.dark('x²', id: 'x2'), MB.eq(id: 'eq'), MB.root('√', id: 'rR'), MB.green('9', id: '0'),
    ],
    duration: const Duration(milliseconds: 6000),
    interactiveTargetId: 'rL',
    errorFeedback: '¡Arrastra la raíz cuadrada (√) para destruir el exponente!',
  ),
  TutorialScene(
    time: '0:16',
    subtitle: "La raíz destruye el exponente dejando solo a la 'x'. √9 es 3.",
    speechBubble: '¡Destrucción!',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.dark('x', id: 'x2'), MB.eq(id: 'eq'), MB.action('±3', id: '0'),
    ],
    duration: const Duration(milliseconds: 6000),
  ),
  TutorialScene(
    time: '0:20',
    subtitle: "Pero OJO: (-3) × (-3) también da 9. Las cuadráticas siempre generan DOS realidades (±).",
    speechBubble: '¡El Multiverso!',
    bunnyAction: BunnyAction.celebrate,
    bunnyAlignment: const Alignment(0.0, 0.8),
    mathBlocks: [
      MB.dark('x = 3', id: 'x2'), MB.dark('   ó   ', id: 'o'), MB.dark('x = -3', id: '0'),
    ],
    duration: const Duration(milliseconds: 7000),
  ),
];

// ─── GUIÓN COMPLETO: 2x³ = 16 (Ecuación Cúbica) ────────────────────────────
final List<TutorialScene> cubicTutorialScenes = [
  TutorialScene(
    time: '0:00',
    subtitle: "El exponente ³ representa el volumen de un CUBO perfecto en 3D.",
    speechBubble: '¡A la tercera dimensión!',
    bunnyAction: BunnyAction.greet,
    bunnyAlignment: const Alignment(0.0, 0.0),
    bunnySize: 420.0,
    mathBlocks: [],
    duration: const Duration(milliseconds: 5000),
  ),
  TutorialScene(
    time: '0:03',
    subtitle: "Como siempre, aplicamos la regla de despejar primero a los intrusos lejanos.",
    speechBubble: 'Aislar x³',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.green('2', id: '2'), MB.dark('x³', id: 'x3'), MB.eq(id: 'eq'), MB.green('16', id: '16'),
    ],
    duration: const Duration(milliseconds: 5500),
    interactiveTargetId: '2',
    errorFeedback: '¡Arrastra el 2 hacia el otro lado para que pase multiplicando/dividiendo!',
  ),
  TutorialScene(
    time: '0:06',
    subtitle: "El 2 pasa dividiendo debajo del 16.",
    speechBubble: 'Dividir',
    bunnyAction: BunnyAction.none,
    bunnyAlignment: const Alignment(-0.8, 0.8),
    mathBlocks: [
      MB.dark('x³', id: 'x3'), MB.eq(id: 'eq'), MB.frac('16', '2', id: 'frac'),
    ],
    duration: const Duration(milliseconds: 5500),
  ),
  TutorialScene(
    time: '0:09',
    subtitle: "Esto nos deja que nuestra x al cubo tiene un volumen final de 8.",
    speechBubble: 'La mitad',
    bunnyAction: BunnyAction.startTalking,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.dark('x³', id: 'x3'), MB.eq(id: 'eq'), MB.green('8', id: 'frac'),
    ],
    duration: const Duration(milliseconds: 5000),
  ),
  TutorialScene(
    time: '0:12',
    subtitle: "Para deshacer el exponente 3, invocamos el poder de la Raíz Cúbica (∛).",
    speechBubble: 'Raíz Cúbica',
    bunnyAction: BunnyAction.magicFlip,
    bunnyAlignment: const Alignment(0.8, 0.8),
    mathBlocks: [
      MB.root('∛', id: 'rL'), MB.dark('x³', id: 'x3'), MB.eq(id: 'eq'), MB.root('∛', id: 'rR'), MB.green('8', id: 'frac'),
    ],
    duration: const Duration(milliseconds: 6000),
  ),
  TutorialScene(
    time: '0:16',
    subtitle: "¿Qué número multiplicado por sí mismo tres veces da 8? ¡Solo el 2! (2×2×2=8).",
    speechBubble: '¡Solución Única!',
    bunnyAction: BunnyAction.celebrate,
    bunnyAlignment: const Alignment(0.0, 0.8),
    mathBlocks: [
      MB.dark('x', id: 'x3'), MB.eq(id: 'eq'), MB.green('2', id: 'frac'),
    ],
    duration: const Duration(milliseconds: 6500),
  ),
];

