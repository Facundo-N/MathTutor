import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math' show sqrt, pow;
import '../../services/math_api_service.dart';
import '../../providers/sesion_matematica_controller.dart';

// Datos del Juego
final List<Map<String, dynamic>> gameLevels = [
  {
    'id': 1,
    'title': "Nivel 1: Ecuaciones Lineales (ax + b = c)",
    'tutorial': [
      {
        'text':
            "¡Bienvenido a la Academia! Una ecuación es como una balanza perfecta. Nuestro objetivo es descubrir el valor oculto de la 'x'.",
        'equation': [
          {'id': 'tut1', 'type': 'dark', 'text': 'ax + b'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tut2', 'type': 'dark', 'text': 'c'},
        ],
      },
      {
        'text':
            "Regla de oro: Para despejar la 'x', debemos aplicar OPERACIONES INVERSAS a AMBOS lados de la balanza.",
        'equation': [
          {'id': 'act1', 'type': 'action', 'text': 'Lo que suma'},
          {'id': 'eq', 'type': 'text', 'text': '➡️'},
          {'id': 'act2', 'type': 'action', 'text': 'Pasa restando'},
        ],
      },
    ],
    'steps': [
      {
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': '3x'},
          {'id': 't2', 'type': 'green', 'text': '+ 6'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '12'},
        ],
        'question': "Aplica la teoría: ¿Cómo eliminamos el +6?",
        'options': [
          {'text': 'Restar 6 (- 6)', 'isCorrect': true},
          {
            'text': 'Sumar 6 (+ 6)',
            'isCorrect': false,
            'errorType': 'traidor_signo',
          },
          {
            'text': 'Dividir por 3',
            'isCorrect': false,
            'errorType': 'orden_operaciones',
          },
        ],
        'reasoning': "Empezamos alejando números sumando/restando.",
      },
      {
        'isVisualExplanation': true,
        'duration': 4000,
        'shatterIds': ['t2', 'act_l'],
        'shatterDelay': 2000,
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': '3x'},
          {'id': 't2', 'type': 'green', 'text': '+ 6'},
          {'id': 'act_l', 'type': 'action', 'text': '- 6', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '12'},
          {'id': 'act_r', 'type': 'action', 'text': '- 6', 'pop': true},
        ],
        'question': "Restamos 6 en ambos lados. (+6 - 6) se vuelve 0.",
      },
      {
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': '3x'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '6', 'pop': true},
        ],
        'question':
            "El 3 multiplica a la 'x' (3 * x = 6). ¿Cómo lo eliminamos?",
        'options': [
          {'text': 'Dividir por 3 (÷ 3)', 'isCorrect': true},
          {
            'text': 'Restar 3 (- 3)',
            'isCorrect': false,
            'errorType': 'operacion_inversa_incorrecta',
          },
        ],
      },
      {
        'isVisualExplanation': true,
        'duration': 4000,
        'shatterIds': ['t1', 'act_l2'],
        'shatterDelay': 2000,
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': '3x'},
          {'id': 'act_l2', 'type': 'action', 'text': '÷ 3', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '6'},
          {'id': 'act_r2', 'type': 'action', 'text': '÷ 3', 'pop': true},
        ],
        'question': "Dividimos. (3 ÷ 3) es 1, dejando a la 'x' libre.",
      },
      {
        'equation': [
          {'id': 'tx', 'type': 'dark', 'text': 'x', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tf', 'type': 'green', 'text': '2', 'pop': true},
        ],
        'question': "¡Ecuación Lineal completada! x = 2",
        'isFinalStep': true,
      },
    ],
  },
  {
    'id': 2,
    'title': "Nivel 2: Propiedad Distributiva",
    'tutorial': [
      {
        'text':
            "¿Qué pasa si hay un número multiplicando a un grupo entre paréntesis?",
        'equation': [
          {'id': 'tut1', 'type': 'dark', 'text': 'a'},
          {'id': 'b1', 'type': 'bracket', 'text': '('},
          {'id': 'tut2', 'type': 'dark', 'text': 'x + b'},
          {'id': 'b2', 'type': 'bracket', 'text': ')'},
        ],
      },
      {
        'text': "Propiedad Distributiva: El número debe multiplicar a TODOS.",
        'equation': [
          {'id': 'act1', 'type': 'action', 'text': 'a*x'},
          {'id': 'op', 'type': 'text', 'text': '+'},
          {'id': 'act2', 'type': 'action', 'text': 'a*b'},
        ],
      },
    ],
    'steps': [
      {
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': '3'},
          {'id': 'b1', 'type': 'bracket', 'text': '('},
          {'id': 't2', 'type': 'dark', 'text': 'x'},
          {'id': 't3', 'type': 'green', 'text': '+ 2'},
          {'id': 'b2', 'type': 'bracket', 'text': ')'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't4', 'type': 'green', 'text': '15'},
        ],
        'question': "¿Cómo rompemos el paréntesis?",
        'options': [
          {'text': 'Multiplicar el 3 por "x" y por "+2"', 'isCorrect': true},
          {
            'text': 'Sumar 3 + 2',
            'isCorrect': false,
            'errorType': 'peras_con_manzanas',
          },
          {
            'text': 'Pasar el 3 restando',
            'isCorrect': false,
            'errorType': 'operacion_inversa_incorrecta',
          },
        ],
        'reasoning':
            "Imagina 3 bolsas con manzanas y peras. Todo se multiplica.",
      },
      {
        'isVisualExplanation': true,
        'duration': 4500,
        'equation': [
          {'id': 'act1', 'type': 'action', 'text': '3 * x', 'pop': true},
          {'id': 'op', 'type': 'text', 'text': '+'},
          {'id': 'act2', 'type': 'action', 'text': '3 * 2', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't4', 'type': 'green', 'text': '15'},
        ],
        'question': "El 3 se 'distribuye'.",
      },
      {
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': '3x', 'pop': true},
          {'id': 't2', 'type': 'green', 'text': '+ 6', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't4', 'type': 'green', 'text': '15'},
        ],
        'question': "¿Qué eliminamos primero?",
        'options': [
          {'text': 'Restar 6 (- 6)', 'isCorrect': true},
          {
            'text': 'Dividir por 3',
            'isCorrect': false,
            'errorType': 'orden_operaciones',
          },
        ],
      },
      {
        'isVisualExplanation': true,
        'duration': 3000,
        'shatterIds': ['t2', 'act_l'],
        'shatterDelay': 1000,
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': '3x'},
          {'id': 't2', 'type': 'green', 'text': '+ 6'},
          {'id': 'act_l', 'type': 'action', 'text': '- 6', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't4', 'type': 'green', 'text': '15'},
          {'id': 'act_r', 'type': 'action', 'text': '- 6', 'pop': true},
        ],
        'question': "Cancelamos el +6...",
      },
      {
        'equation': [
          {'id': 'tx', 'type': 'dark', 'text': 'x', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tf', 'type': 'green', 'text': '3', 'pop': true},
        ],
        'question': "¡Excelente! (15 - 6 = 9) y (9 ÷ 3 = 3). x = 3",
        'isFinalStep': true,
      },
    ],
  },
  {
    'id': 3,
    'title': "Nivel 3: Cuadráticas y Raíces",
    'tutorial': [
      {
        'text':
            "Un término 'x²' representa matemáticamente el ÁREA de un cuadrado.",
        'equation': [
          {'id': 'tut1', 'type': 'dark', 'text': 'x'},
          {'id': 'tut2', 'type': 'dark', 'text': '²'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tut3', 'type': 'green', 'text': 'Área'},
        ],
      },
      {
        'text': "Su operación destructora: la Raíz Cuadrada (√).",
        'equation': [
          {'id': 'act1', 'type': 'action', 'text': '√'},
          {'id': 'b1', 'type': 'bracket', 'text': '('},
          {'id': 'tut1', 'type': 'dark', 'text': 'x'},
          {'id': 'tut2', 'type': 'dark', 'text': '²'},
          {'id': 'b2', 'type': 'bracket', 'text': ')'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tut1b', 'type': 'dark', 'text': 'x'},
        ],
      },
      {
        'text':
            "¡Cuidado con el multiverso! Toda raíz cuadrada arroja DOS respuestas. Ejemplo: √9 = ±3",
        'equation': [
          {'id': 'tut1', 'type': 'dark', 'text': 'x'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'act1', 'type': 'action', 'text': '±'},
          {'id': 'tut3', 'type': 'green', 'text': 'N'},
        ],
      },
    ],
    'steps': [
      {
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': 'x²'},
          {'id': 't2', 'type': 'green', 'text': '- 7'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '9'},
        ],
        'question': "Aplica lo básico primero: dejemos la x² sola.",
        'options': [
          {'text': 'Sumar 7 (+ 7)', 'isCorrect': true},
          {
            'text': 'Aplicar raíz a todo ya',
            'isCorrect': false,
            'errorType': 'orden_operaciones',
          },
        ],
      },
      {
        'isVisualExplanation': true,
        'duration': 2500,
        'shatterIds': ['t2', 'act1'],
        'shatterDelay': 1000,
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': 'x²'},
          {'id': 't2', 'type': 'green', 'text': '- 7'},
          {'id': 'act1', 'type': 'action', 'text': '+ 7', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '9'},
          {'id': 'act2', 'type': 'action', 'text': '+ 7', 'pop': true},
        ],
        'question': "Cancelamos el -7...",
      },
      {
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': 'x²'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '16', 'pop': true},
        ],
        'question': "x² = 16. ¿Qué operación divina usamos?",
        'options': [
          {'text': 'Aplicar raíz cuadrada (√)', 'isCorrect': true},
          {
            'text': 'Dividir entre 2',
            'isCorrect': false,
            'errorType': 'operacion_inversa_incorrecta',
          },
        ],
        'reasoning':
            "La Raíz Cuadrada (√) nos pregunta: ¿Qué número multiplicado por sí mismo da 16?",
      },
      {
        'isVisualExplanation': true,
        'duration': 5500,
        'shatterIds': ['root_l', 'pow'],
        'shatterDelay': 3500,
        'equation': [
          {'id': 'root_l', 'type': 'action', 'text': '√', 'pop': true},
          {'id': 'b1', 'type': 'bracket', 'text': '('},
          {'id': 'tx', 'type': 'dark', 'text': 'x'},
          {'id': 'pow', 'type': 'dark', 'text': '²'},
          {'id': 'b2', 'type': 'bracket', 'text': ')'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'root_r', 'type': 'action', 'text': '√', 'pop': true},
          {'id': 't3', 'type': 'green', 'text': '16'},
        ],
        'question': "La raíz (√) anula a la potencia (²).",
      },
      {
        'equation': [
          {'id': 'tx', 'type': 'dark', 'text': 'x', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tf', 'type': 'action', 'text': '± 4', 'pop': true},
        ],
        'question': "¿Qué significa este ±4?",
        'options': [
          {'text': 'Que x vale 4 o -4', 'isCorrect': true},
          {
            'text': 'Es un error',
            'isCorrect': false,
            'errorType': 'omision_raiz_negativa',
          },
        ],
        'reasoning':
            "Tanto (4 × 4) como (-4 × -4) cumplen. Una ecuación cuadrática abre dos caminos de realidad.",
      },
      {
        'equation': [
          {'id': 'tx', 'type': 'dark', 'text': 'x'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't4', 'type': 'green', 'text': '4'},
          {'id': 'o', 'type': 'text', 'text': 'ó'},
          {'id': 'tx2', 'type': 'dark', 'text': 'x'},
          {'id': 'eq2', 'type': 'text', 'text': '='},
          {'id': 'tm4', 'type': 'green', 'text': '-4'},
        ],
        'question': "Nivel Cuadrático superado con éxito.",
        'isFinalStep': true,
      },
    ],
  },
  {
    'id': 4,
    'title': "Nivel 4: Factorización y Producto Cero",
    'tutorial': [
      {
        'text':
            "Factorizar es el arte inverso de multiplicar. Transforma una ecuación polinómica en piezas pequeñas.",
        'equation': [
          {'id': 'tut1', 'type': 'dark', 'text': 'Suma Compleja'},
          {'id': 'eq', 'type': 'text', 'text': '➡️'},
          {'id': 'tut2', 'type': 'action', 'text': '(A) * (B)'},
        ],
      },
      {
        'text':
            "Si la multiplicación de dos grupos da cero... ¡Alguien debe ser cero!",
        'equation': [
          {'id': 'tut1', 'type': 'dark', 'text': 'A * B'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tut2', 'type': 'green', 'text': '0'},
        ],
      },
      {
        'text': "No hay otra ley: A = 0, o B = 0.",
        'equation': [
          {'id': 'tut1', 'type': 'action', 'text': 'A = 0'},
          {'id': 'eq', 'type': 'text', 'text': 'ó'},
          {'id': 'tut2', 'type': 'action', 'text': 'B = 0'},
        ],
      },
    ],
    'steps': [
      {
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': 'x² + 5x + 6'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '0'},
        ],
        'question':
            "Trinomio igual a 0. Busquemos dos números que sumen 5 y multipliquen 6.",
        'options': [
          {'text': 'Factorizar como (x + 2)(x + 3)', 'isCorrect': true},
          {
            'text': 'Pasar el 6 restando',
            'isCorrect': false,
            'errorType': 'movimiento_invalido',
          },
        ],
        'reasoning': "2+3=5 y 2×3=6. Ahora tenemos grupos limpios.",
      },
      {
        'equation': [
          {'id': 'g1', 'type': 'action', 'text': '(x + 2)', 'pop': true},
          {'id': 'g2', 'type': 'action', 'text': '(x + 3)', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '0'},
        ],
        'question': "Aplica la Propiedad del Producto Cero:",
        'options': [
          {'text': 'Separar asumiendo que un grupo vale 0', 'isCorrect': true},
          {
            'text': 'Multiplicar todo',
            'isCorrect': false,
            'errorType': 'expansion_innecesaria',
          },
        ],
      },
      {
        'isVisualExplanation': true,
        'duration': 5000,
        'equation': [
          {'id': 'g1', 'type': 'dark', 'text': 'x + 2 = 0'},
          {'id': 'o', 'type': 'text', 'text': '🔴', 'pop': true},
          {'id': 'g2', 'type': 'dark', 'text': 'x + 3 = 0'},
        ],
        'question': "La ecuación se 'rompe' en dos inofensivas.",
        'reasoning': "Pasamos de una cuadrática a dos lineales rápidas.",
      },
      {
        'equation': [
          {'id': 'tx', 'type': 'dark', 'text': 'x', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't4', 'type': 'green', 'text': '-2'},
          {'id': 'o', 'type': 'text', 'text': 'ó'},
          {'id': 'tx2', 'type': 'dark', 'text': 'x'},
          {'id': 'eq2', 'type': 'text', 'text': '='},
          {'id': 'tm4', 'type': 'green', 'text': '-3'},
        ],
        'question': "¡Factorizado magistralmente!",
        'isFinalStep': true,
      },
    ],
  },
  {
    'id': 5,
    'title': "Nivel 5: Ecuaciones Cúbicas",
    'tutorial': [
      {
        'text':
            "A la Tercera Dimensión. Un término 'x³' representa el VOLUMEN de un cubo.",
        'equation': [
          {'id': 'tut1', 'type': 'dark', 'text': 'x'},
          {'id': 'tut2', 'type': 'dark', 'text': '³'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tut3', 'type': 'green', 'text': 'Volumen'},
        ],
      },
      {
        'text': "Operación opuesta: La Raíz Cúbica (∛).",
        'equation': [
          {'id': 'act1', 'type': 'action', 'text': '∛'},
          {'id': 'b1', 'type': 'bracket', 'text': '('},
          {'id': 'tut1', 'type': 'dark', 'text': 'x'},
          {'id': 'tut2', 'type': 'dark', 'text': '³'},
          {'id': 'b2', 'type': 'bracket', 'text': ')'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tut1b', 'type': 'dark', 'text': 'x'},
        ],
      },
      {
        'text':
            "A diferencia del cuadrado, los cubos NO tienen multiverso. Resultado directo.",
        'equation': [
          {'id': 'tut1', 'type': 'dark', 'text': 'Respuesta'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tut2', 'type': 'green', 'text': 'Única'},
        ],
      },
    ],
    'steps': [
      {
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': '2x³'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '16'},
        ],
        'question': "¿Qué hacemos con el 2?",
        'options': [
          {'text': 'Dividir entre 2', 'isCorrect': true},
          {
            'text': 'Aplicar raíz cúbica',
            'isCorrect': false,
            'errorType': 'orden_operaciones',
          },
        ],
      },
      {
        'equation': [
          {'id': 't1', 'type': 'dark', 'text': 'x³', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 't3', 'type': 'green', 'text': '8', 'pop': true},
        ],
        'question':
            "Tenemos que un cubo tiene volumen de 8 (x³ = 8). ¿Cómo lo rompemos?",
        'options': [
          {'text': 'Aplicar Raíz Cúbica (∛)', 'isCorrect': true},
          {
            'text': 'Dividir por 3',
            'isCorrect': false,
            'errorType': 'operacion_inversa_incorrecta',
          },
        ],
        'reasoning':
            "Preguntamos: ¿Qué número multiplicado por sí mismo 3 veces seguidas da 8?",
      },
      {
        'isVisualExplanation': true,
        'duration': 5500,
        'shatterIds': ['root_l', 'pow'],
        'shatterDelay': 3000,
        'equation': [
          {'id': 'root_l', 'type': 'action', 'text': '∛', 'pop': true},
          {'id': 'b1', 'type': 'bracket', 'text': '('},
          {'id': 'tx', 'type': 'dark', 'text': 'x'},
          {'id': 'pow', 'type': 'dark', 'text': '³'},
          {'id': 'b2', 'type': 'bracket', 'text': ')'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'root_r', 'type': 'action', 'text': '∛', 'pop': true},
          {'id': 't3', 'type': 'green', 'text': '8'},
        ],
        'question':
            "La raíz cúbica destruye el exponente 3. Derecha: ∛8 = 2 (2x2x2=8).",
      },
      {
        'equation': [
          {'id': 'tx', 'type': 'dark', 'text': 'x', 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {'id': 'tf', 'type': 'green', 'text': '2', 'pop': true},
        ],
        'question':
            "¡Has conquistado todas las dimensiones del álgebra! x = 2.",
        'isFinalStep': true,
      },
    ],
  },
];

class EquationBlockState {
  final String id;
  final String type;
  final String text;
  final bool popOnInit;
  String animState;

  EquationBlockState({
    required this.id,
    required this.type,
    required this.text,
    this.popOnInit = false,
    this.animState = 'normal',
  });

  factory EquationBlockState.fromMap(Map<String, dynamic> map) {
    return EquationBlockState(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      text: map['text'] ?? '',
      popOnInit: map['pop'] == true,
      animState: map['pop'] == true ? 'pop' : 'normal',
    );
  }
}

class DestruirEcuacionesSeleccionTemplate extends StatefulWidget {
  final Map<String, dynamic> exerciseData;
  final VoidCallback onExerciseCompleted;

  const DestruirEcuacionesSeleccionTemplate({
    super.key,
    required this.exerciseData,
    required this.onExerciseCompleted,
  });

  @override
  State<DestruirEcuacionesSeleccionTemplate> createState() =>
      _DestruirEcuacionesSeleccionTemplateState();
}

class _DestruirEcuacionesSeleccionTemplateState
    extends State<DestruirEcuacionesSeleccionTemplate> {
  int _currentStepIndex = 0;
  bool _isTutorialMode = true;
  int _tutorialStepIndex = 0;

  double _parseNum(String s) {
    if (s.isEmpty || s == "+" || s == "-") return 1.0;
    return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  }

  String _formatNum(double n) {
    if ((n - n.roundToDouble()).abs() < 0.0001) {
      return n.round().toString();
    }
    String s = n.toStringAsFixed(1);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s.replaceAll('.', ',');
  }

  List<EquationBlockState> _equationState = [];
  List<EquationBlockState> _ghostEquationState = [];
  bool _isErrorState = false;
  int? _selectedWrongOptionIndex;
  int? _selectedCorrectOptionIndex;
  bool _gameFinished = false;
  bool _isProcessingStep = false;
  bool _showGhostAnimation = false;

  late SesionMatematicaController _sesionController;
  late Map<String, dynamic> _dynamicLevel;

  Timer? _shatterTimer;
  Timer? _nextTimer;
  Timer? _errorTimer;
  Timer? _correctTimer;
  Timer? _ghostShatterTimer;

  Map<String, dynamic> get currentLevel => _dynamicLevel;

  Map<String, dynamic> get currentStep =>
      (currentLevel['steps'] as List).elementAt(_currentStepIndex);

  Map<String, dynamic>? get currentTutorialStep {
    if (currentLevel['tutorial'] == null) return null;
    return (currentLevel['tutorial'] as List).elementAt(_tutorialStepIndex);
  }

  bool get isLevelComplete => currentStep['isFinalStep'] == true;

  @override
  void initState() {
    super.initState();
    _sesionController = SesionMatematicaController();
    _generateDynamicLevel();
    _loadStepState();
  }

  void _generateDynamicLevel() {
    final Map<String, dynamic> uiConfig =
        widget.exerciseData['ui_config'] ?? {};
    String eqStr = widget.exerciseData['equation'] ?? '';
    // Normalizar símbolos del teclado y superscripts unicode
    eqStr = eqStr
        .replaceAll('\u2212', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('÷', '/')
        .replaceAll('×', '*')
        .replaceAll(',', '.')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .trim();

    debugPrint('[DestruirSeleccion] ecuación recibida: "$eqStr"');

    // Si la ecuación está vacía mostrar mensaje claro en lugar del x=0
    if (eqStr.isEmpty) eqStr = 'x + 1 = 1';

    final String correctAnswer =
        widget.exerciseData['correct_answer'] ?? 'x = ?';
    List<dynamic> optionsRaw = uiConfig['options'] ?? [];
    List<dynamic> piecesRaw = widget.exerciseData['pieces'] ?? [];
    List<String> pieces = piecesRaw.map((e) => e.toString()).toList();

    if (pieces.isEmpty) {
      pieces = eqStr.split(' ');
    }

    final equationBlocks = pieces.asMap().entries.map((e) {
      String text = e.value.trim();
      String type = 'dark';
      if (text == '=' || text == '+' || text == '-') type = 'text';
      return {'id': 'p_${e.key}', 'type': type, 'text': text};
    }).toList();

    List<Map<String, dynamic>> dynamicSteps = [];
    String normalizedEq = eqStr.replaceAll(' ', '');

    // --- RAMA CUADRÁTICA / CÚBICA: ax^n + b = c ---
    final matchHigh = RegExp(
      r'^([+-]?\d*(?:[\.,]\d+)?)([a-zA-Z]+)\^([23])([+-]\d*(?:[\.,]\d+)?)?=(-?\d*(?:[\.,]\d+)?)$',
    ).firstMatch(normalizedEq);

    if (matchHigh != null) {
      String aStr = matchHigh.group(1)!;
      final String literal = matchHigh.group(2)!;
      final int exp = matchHigh.group(3) == '3' ? 3 : 2;
      final String expChar = exp == 3 ? '³' : '²';
      final String rootSym = exp == 3 ? '∛' : '√';
      final String? opText = matchHigh.group(4);
      final String rightStr = matchHigh.group(5)!;

      if (aStr.isEmpty || aStr == '+') aStr = '1';
      if (aStr == '-') aStr = '-1';
      final double a = _parseNum(aStr);
      final bool hasOp = opText != null;
      final String op = hasOp ? opText.substring(0, 1) : '+';
      final double opVal = hasOp ? _parseNum(opText.substring(1)) : 0;
      final double rightNum = _parseNum(rightStr);
      final double afterOp = hasOp
          ? (op == '+' ? rightNum - opVal : rightNum + opVal)
          : rightNum;
      final double underRoot = a != 0 ? (afterOp / a) : afterOp;

      final double exactAns = exp == 3
          ? (underRoot >= 0
              ? pow(underRoot, 1 / 3).toDouble()
              : -pow(underRoot.abs(), 1 / 3).toDouble())
          : (underRoot >= 0 ? sqrt(underRoot) : 0);
      final String ansStr = _formatNum(exactAns);

      dynamicSteps = [];
      if (hasOp) {
        final String invOp = op == '+' ? '-' : '+';
        dynamicSteps.add({
          'equation': [
            {
              'id': 'xPow',
              'type': 'dark',
              'text': '${a == 1 ? "" : (a == -1 ? "-" : aStr)}$literal$expChar',
            },
            {'id': 'op', 'type': 'green', 'text': opText},
            {'id': 'eq', 'type': 'text', 'text': '='},
            {'id': 'res', 'type': 'green', 'text': rightStr},
          ],
          'question':
              "Primero, despejemos $literal$expChar. ¿Cómo eliminamos el $opText?",
          'options': [
            {
              'text':
                  '${invOp == '-' ? 'Restar' : 'Sumar'} ${_formatNum(opVal)} ($invOp ${_formatNum(opVal)})',
              'isCorrect': true,
            },
            {
              'text': 'Aplicar $rootSym directo',
              'isCorrect': false,
              'errorType': 'orden_operaciones',
            },
          ],
          'reasoning': 'Primero move los números, luego aplicamos la raíz.',
        });
        dynamicSteps.add({
          'isVisualExplanation': true,
          'duration': 3000,
          'shatterIds': ['op', 'act'],
          'shatterDelay': 1000,
          'equation': [
            {
              'id': 'xPow',
              'type': 'dark',
              'text': '${a == 1 ? "" : (a == -1 ? "-" : aStr)}$literal$expChar',
            },
            {
              'id': 'act',
              'type': 'action',
              'text': '$invOp ${_formatNum(opVal)}',
              'pop': true,
            },
            {'id': 'eq', 'type': 'text', 'text': '='},
            {'id': 'res', 'type': 'green', 'text': rightStr},
            {
              'id': 'act2',
              'type': 'action',
              'text': '$invOp ${_formatNum(opVal)}',
              'pop': true,
            },
          ],
          'question': 'Cancelamos el $opText...',
        });
      }

      if (a != 1) {
        dynamicSteps.add({
          'equation': [
            {'id': 'a', 'type': 'green', 'text': aStr},
            {'id': 'xPow', 'type': 'dark', 'text': '$literal$expChar'},
            {'id': 'eq', 'type': 'text', 'text': '='},
            {
              'id': 'res',
              'type': 'green',
              'text': _formatNum(afterOp),
              'pop': true,
            },
          ],
          'question':
              "El $aStr multiplica a $literal$expChar. ¿Cómo lo eliminamos?",
          'options': [
            {'text': 'Dividir entre $aStr (÷ $aStr)', 'isCorrect': true},
            {
              'text': 'Aplicar $rootSym sin dividir',
              'isCorrect': false,
              'errorType': 'orden_operaciones',
            },
          ],
          'reasoning': 'La división cancela la multiplicación.',
        });

        dynamicSteps.add({
          'isVisualExplanation': true,
          'duration': 3000,
          'shatterIds': ['a', 'act'],
          'shatterDelay': 1000,
          'equation': [
            {'id': 'act', 'type': 'action', 'text': '÷ $aStr', 'pop': true},
            {'id': 'a', 'type': 'green', 'text': aStr},
            {'id': 'xPow', 'type': 'dark', 'text': '$literal$expChar'},
            {'id': 'eq', 'type': 'text', 'text': '='},
            {'id': 'res', 'type': 'green', 'text': _formatNum(afterOp)},
            {'id': 'act2', 'type': 'action', 'text': '÷ $aStr', 'pop': true},
          ],
          'question': 'Dividimos entre $aStr a ambos lados...',
        });
      }

      dynamicSteps.add({
        'equation': [
          {'id': 'xPow', 'type': 'dark', 'text': '$literal$expChar'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {
            'id': 'res',
            'type': 'green',
            'text': _formatNum(underRoot),
            'pop': true,
          },
        ],
        'question':
            "$literal$expChar = ${_formatNum(underRoot)}. ¿Qué operación matemática nos libra del exponente $expChar?",
        'options': [
          {
            'text': 'Aplicar raíz ${exp == 3 ? 'cúbica (∛)' : 'cuadrada (√)'}',
            'isCorrect': true,
          },
          {
            'text': 'Dividir entre $exp',
            'isCorrect': false,
            'errorType': 'operacion_inversa_incorrecta',
          },
        ],
        'reasoning':
            'La raíz ${exp == 3 ? 'cúbica anula el exponente 3' : 'cuadrada anula el exponente 2'}.',
      });

      dynamicSteps.add({
        'isVisualExplanation': true,
        'duration': 3000,
        'shatterIds': ['xPow', 'act'],
        'shatterDelay': 1000,
        'equation': [
          {'id': 'act', 'type': 'action', 'text': rootSym, 'pop': true},
          {'id': 'xPow', 'type': 'dark', 'text': '$literal$expChar'},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {
            'id': 'res',
            'type': 'green',
            'text': (underRoot == underRoot.toInt()
                ? underRoot.toInt().toString()
                : underRoot.toStringAsFixed(1)),
          },
          {'id': 'act2', 'type': 'action', 'text': rootSym, 'pop': true},
        ],
        'question': 'Aplicamos raíz a ambos lados...',
      });

      dynamicSteps.add({
        'equation': [
          {'id': 'tx', 'type': 'dark', 'text': literal, 'pop': true},
          {'id': 'eq', 'type': 'text', 'text': '='},
          {
            'id': 'tf',
            'type': 'green',
            'text': exp == 2 ? '±$ansStr' : ansStr,
            'pop': true,
          },
        ],
        'question': '¡Completado! $correctAnswer',
        'isFinalStep': true,
      });
    } else {
      // --- RAMA LINEAL: ax + b = c ---
      final RegExp regex = RegExp(r'^([\-]?\d*(?:[\.,]\d+)?x)([\+\-])(\d*(?:[\.,]\d+)?)=\s*(-?\d*(?:[\.,]\d+)?)$');
      Match? match = regex.firstMatch(normalizedEq);
      if (match != null) {
        String termX = match.group(1)!;
        String op = match.group(2)!;
        String termB = match.group(3)!;
        String termC = match.group(4)!;

        String inverseOp = op == '+' ? '-' : '+';
        String inverseOpName = op == '+' ? 'Restar' : 'Sumar';
        String wrongOpName = op == '+' ? 'Sumar' : 'Restar';

        double bVal = _parseNum(termB);
        double cVal = _parseNum(termC);
        double cMinusB = op == '+' ? (cVal - bVal) : (cVal + bVal);

        String coeffStr = termX.replaceAll('x', '');
        if (coeffStr == '') coeffStr = '1';
        if (coeffStr == '-') coeffStr = '-1';

        dynamicSteps = [
          {
            'equation': [
              {'id': 't1', 'type': 'dark', 'text': termX},
              {'id': 't2', 'type': 'green', 'text': '$op $termB'},
              {'id': 'eq', 'type': 'text', 'text': '='},
              {'id': 't3', 'type': 'green', 'text': termC},
            ],
            'question': "¿Cómo eliminamos el $op $termB?",
            'options': [
              {
                'text': '$inverseOpName $termB ($inverseOp $termB)',
                'isCorrect': true,
              },
              {
                'text': '$wrongOpName $termB ($op $termB)',
                'isCorrect': false,
                'errorType': 'traidor_signo',
              },
              {
                'text': 'Dividir por $coeffStr',
                'isCorrect': false,
                'errorType': 'orden_operaciones',
              },
            ],
            'reasoning': "Empezamos alejando números sumando/restando.",
          },
          {
            'equation': [
              {'id': 't1', 'type': 'dark', 'text': termX},
              {'id': 't2', 'type': 'green', 'text': '$op $termB'},
              {
                'id': 'act_l',
                'type': 'action',
                'text': '$inverseOp $termB',
                'pop': true,
              },
              {'id': 'eq', 'type': 'text', 'text': '='},
              {'id': 't3', 'type': 'green', 'text': termC},
              {
                'id': 'act_r',
                'type': 'action',
                'text': '$inverseOp $termB',
                'pop': true,
              },
            ],
            'question':
                "Al aplicar $inverseOp $termB, ¿qué ocurre en el lado izquierdo con $op $termB $inverseOp $termB?",
            'options': [
              {
                'text': 'Se cancelan (da 0) dejando sola a la incógnita',
                'isCorrect': true,
              },
              {
                'text': 'Se suman y da ${_formatNum(op == '+' ? bVal * 2 : -(bVal * 2))}',
                'isCorrect': false,
                'errorType': 'error_calculo',
              },
              {
                'text': 'Pasan al otro lado multiplicando',
                'isCorrect': false,
                'errorType': 'operacion_inversa_incorrecta',
              },
            ],
            'reasoning':
                "Un número sumado/restado por su opuesto siempre da cero.",
          },
          {
            'isVisualExplanation': true,
            'duration': 4000,
            'shatterIds': ['t2', 'act_l'],
            'shatterDelay': 1000,
            'equation': [
              {'id': 't1', 'type': 'dark', 'text': termX},
              {'id': 't2', 'type': 'green', 'text': '$op $termB'},
              {'id': 'act_l', 'type': 'action', 'text': '$inverseOp $termB'},
              {'id': 'eq', 'type': 'text', 'text': '='},
              {'id': 't3', 'type': 'green', 'text': termC},
              {'id': 'act_r', 'type': 'action', 'text': '$inverseOp $termB'},
            ],
            'question': "¡Exacto! Se cancelan mutuamente.",
          },
          {
            'equation': [
              {'id': 't1', 'type': 'dark', 'text': termX},
              {'id': 'eq', 'type': 'text', 'text': '='},
              {
                'id': 'calc',
                'type': 'green',
                'text': '$cVal $inverseOp $bVal',
                'pop': true,
              },
            ],
            'question': "¿Cuál es el resultado de $cVal $inverseOp $bVal?",
            'options': [
              {'text': _formatNum(cMinusB), 'isCorrect': true},
              {
                'text': _formatNum(cVal + bVal == cMinusB ? cMinusB + 2.1 : cVal + bVal),
                'isCorrect': false,
                'errorType': 'error_calculo',
              },
              {
                'text': _formatNum(cMinusB + 4.2),
                'isCorrect': false,
                'errorType': 'error_calculo',
              },
            ],
            'reasoning': "Resuelve la operación para simplificar la ecuación.",
          },
        ];

        if (coeffStr != '1' && coeffStr != '-1') {
          double coeffVal = _parseNum(coeffStr);
          double finalX = coeffVal != 0 ? cMinusB / coeffVal : cMinusB;
          dynamicSteps.addAll([
            {
              'equation': [
                {'id': 't1', 'type': 'dark', 'text': termX},
                {'id': 'eq', 'type': 'text', 'text': '='},
                {'id': 't3', 'type': 'green', 'text': _formatNum(cMinusB), 'pop': true},
              ],
              'question':
                  "El $coeffStr multiplica a la 'x'. ¿Cómo lo eliminamos?",
              'options': [
                {
                  'text': 'Dividir por $coeffStr (÷ $coeffStr)',
                  'isCorrect': true,
                },
                {
                  'text': 'Restar $coeffStr (- $coeffStr)',
                  'isCorrect': false,
                  'errorType': 'operacion_inversa_incorrecta',
                },
              ],
            },
            {
              'equation': [
                {'id': 't1', 'type': 'dark', 'text': termX},
                {
                  'id': 'act_l2',
                  'type': 'action',
                  'text': '÷ $coeffStr',
                  'pop': true,
                },
                {'id': 'eq', 'type': 'text', 'text': '='},
                {'id': 't3', 'type': 'green', 'text': '$cMinusB'},
                {
                  'id': 'act_r2',
                  'type': 'action',
                  'text': '÷ $coeffStr',
                  'pop': true,
                },
              ],
              'question':
                  "Al dividir por $coeffStr, ¿qué ocurre en el lado izquierdo con $coeffStr ÷ $coeffStr?",
              'options': [
                {
                  'text': 'Se cancelan (da 1) dejando sola a la x',
                  'isCorrect': true,
                },
                {
                  'text': 'Se restan y da 0',
                  'isCorrect': false,
                  'errorType': 'error_calculo',
                },
                {
                  'text': 'Pasan al otro lado dividiendo doble',
                  'isCorrect': false,
                  'errorType': 'operacion_inversa_incorrecta',
                },
              ],
              'reasoning': "Un número dividido por sí mismo siempre da uno.",
            },
            {
              'isVisualExplanation': true,
              'duration': 4000,
              'shatterIds': ['t1', 'act_l2'],
              'shatterDelay': 1000,
              'equation': [
                {'id': 't1', 'type': 'dark', 'text': termX},
                {'id': 'act_l2', 'type': 'action', 'text': '÷ $coeffStr'},
                {'id': 'eq', 'type': 'text', 'text': '='},
                {'id': 't3', 'type': 'green', 'text': '$cMinusB'},
                {'id': 'act_r2', 'type': 'action', 'text': '÷ $coeffStr'},
              ],
              'question': "¡Exacto! Se cancelan mutuamente.",
            },
            {
              'equation': [
                {'id': 't1', 'type': 'dark', 'text': 'x'},
                {'id': 'eq', 'type': 'text', 'text': '='},
                {
                  'id': 'calc2',
                  'type': 'green',
                  'text': '${_formatNum(cMinusB)} ÷ ${_formatNum(coeffVal)}',
                  'pop': true,
                },
              ],
              'question': "¿Cuál es el resultado de ${_formatNum(cMinusB)} ÷ ${_formatNum(coeffVal)}?",
              'options': [
                {'text': _formatNum(finalX), 'isCorrect': true},
                {
                  'text': _formatNum(finalX + 2.4),
                  'isCorrect': false,
                  'errorType': 'error_calculo',
                },
                {
                  'text': _formatNum(cMinusB * coeffVal),
                  'isCorrect': false,
                  'errorType': 'error_calculo',
                },
              ],
              'reasoning':
                  "Divide ambos números para encontrar el valor de 'x'.",
            },
          ]);
        }

        dynamicSteps.add({
          'equation': [
            {'id': 'tx', 'type': 'dark', 'text': 'x', 'pop': true},
            {'id': 'eq', 'type': 'text', 'text': '='},
            {
              'id': 'tf',
              'type': 'green',
              'text': correctAnswer.contains('=')
                  ? correctAnswer.split('=').last.trim()
                  : correctAnswer,
              'pop': true,
            },
          ],
          'question': "¡Ecuación Lineal completada! $correctAnswer",
          'isFinalStep': true,
        });
      } else {
        // --- RAMA GENÉRICA (fallback) ---
        List<Map<String, dynamic>> finalOptions = [];
        if (optionsRaw.isNotEmpty) {
          finalOptions = optionsRaw
              .map((o) => Map<String, dynamic>.from(o as Map))
              .toList();
        } else {
          finalOptions = [
            {'text': 'Resolver a $correctAnswer', 'isCorrect': true},
            {
              'text': 'Sumar en lugar de restar',
              'isCorrect': false,
              'errorType': 'operacion_inversa_incorrecta',
            },
            {
              'text': 'Confundir el signo',
              'isCorrect': false,
              'errorType': 'traidor_signo',
            },
            {
              'text': 'Operar mal el orden',
              'isCorrect': false,
              'errorType': 'orden_operaciones',
            },
          ];
        }

        dynamicSteps = [
          {
            'equation': equationBlocks,
            'question': "¿Qué paso darías para resolver $eqStr?",
            'options': finalOptions,
          },
          {
            'equation': [
              {
                'id': 'tx',
                'type': 'dark',
                'text': correctAnswer.contains('=')
                    ? correctAnswer.split('=').first.trim()
                    : 'x',
                'pop': true,
              },
              {'id': 'eq', 'type': 'text', 'text': '='},
              {
                'id': 'tf',
                'type': 'green',
                'text': correctAnswer.contains('=')
                    ? correctAnswer.split('=').last.trim()
                    : correctAnswer,
                'pop': true,
              },
            ],
            'question': "¡Ecuación completada! $correctAnswer",
            'isFinalStep': true,
          },
        ];
      } // end else genérico
    } // end else (no es cuadrática/cúbica)

    _dynamicLevel = {
      'id': 1,
      'title': "Desafío Personalizado",
      'tutorial': [
        {
          'text':
              "Una ecuación es como una balanza perfecta. Nuestro objetivo es descubrir el valor oculto de la 'x'.",
          'equation': [
            {'id': 'tut1', 'type': 'dark', 'text': 'ax + b'},
            {'id': 'eq', 'type': 'text', 'text': '='},
            {'id': 'tut2', 'type': 'dark', 'text': 'c'},
          ],
        },
        {
          'text':
              "Regla de oro: Para despejar la 'x', debemos aplicar OPERACIONES INVERSAS a AMBOS lados de la balanza.",
          'equation': [
            {'id': 'act1', 'type': 'action', 'text': 'Lo que suma'},
            {'id': 'eq', 'type': 'text', 'text': '➡️'},
            {'id': 'act2', 'type': 'action', 'text': 'Pasa restando'},
          ],
        },
      ],
      'steps': dynamicSteps,
    };
  }

  @override
  void dispose() {
    _shatterTimer?.cancel();
    _nextTimer?.cancel();
    _errorTimer?.cancel();
    _correctTimer?.cancel();
    _sesionController.dispose();
    super.dispose();
  }

  void _loadStepState() {
    if (_isTutorialMode) return;

    final eqList = currentStep['equation'] as List;
    setState(() {
      _equationState = eqList
          .map((e) => EquationBlockState.fromMap(e as Map<String, dynamic>))
          .toList();
    });

    if (currentStep['isVisualExplanation'] == true) {
      _isProcessingStep = true;

      // Programmed shatter if provided
      if (currentStep['shatterIds'] != null) {
        final shatterList = (currentStep['shatterIds'] as List).cast<String>();
        final delay = currentStep['shatterDelay'] ?? 1500;
        _shatterTimer = Timer(Duration(milliseconds: delay as int), () {
          if (mounted) {
            setState(() {
              for (var block in _equationState) {
                if (shatterList.contains(block.id)) {
                  block.animState = 'shatter';
                }
              }
            });
          }
        });
      }

      // Automatically next step
      final dur = currentStep['duration'] ?? 3000;
      _nextTimer = Timer(Duration(milliseconds: dur as int), () {
        if (mounted) {
          setState(() {
            _currentStepIndex++;
            _isProcessingStep = false;
            _loadStepState();
          });
        }
      });
    }
  }

  void _handleTutorialNext() {
    final tutorialLen = (currentLevel['tutorial'] as List).length;
    if (_tutorialStepIndex < tutorialLen - 1) {
      setState(() {
        _tutorialStepIndex++;
      });
    } else {
      setState(() {
        _isTutorialMode = false;
        _tutorialStepIndex = 0;
        _loadStepState();
      });
    }
  }

  Future<void> _handleOptionClick(
    Map<String, dynamic> option,
    int index,
  ) async {
    if (_isProcessingStep ||
        _isErrorState ||
        isLevelComplete ||
        currentStep['isVisualExplanation'] == true ||
        _isTutorialMode) {
      return;
    }

    if (option['isCorrect'] == true) {
      setState(() {
        _isProcessingStep = true;
        _selectedCorrectOptionIndex = index;
      });
      _correctTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _currentStepIndex++;
            _selectedCorrectOptionIndex = null;
            _isProcessingStep = false;
            _loadStepState();
          });
        }
      });
    } else {
      // Registrar error en el local state para la hiperpersonalización (Fases 1 y 2 MVP)
      final errorType = option['errorType'] as String? ?? 'error_generico';
      _sesionController.registrarError(errorType);
      final nivelAyuda = _sesionController.getNivelAyuda(errorType);

      setState(() {
        _isErrorState = true;
        _selectedWrongOptionIndex = index;
        if (nivelAyuda >= 2) {
          _isProcessingStep = true; // Mostrar loader temporalmente
        }
        if (nivelAyuda >= 3) {
          _showGhostAnimation = true; // Fantasma después de 3 errores

          // Cargar temporálmente el siguiente paso como fantasma
          if (_currentStepIndex + 1 < (currentLevel['steps'] as List).length) {
            final nextStep =
                (currentLevel['steps'] as List)[_currentStepIndex + 1];
            if (nextStep['equation'] != null) {
              final eqList = nextStep['equation'] as List;
              _ghostEquationState = eqList
                  .map(
                    (e) =>
                        EquationBlockState.fromMap(e as Map<String, dynamic>),
                  )
                  .toList();

              // Programar animación de destrucción si existe
              if (nextStep['shatterIds'] != null) {
                final shatterList = (nextStep['shatterIds'] as List)
                    .cast<String>();
                final delay = nextStep['shatterDelay'] ?? 1500;
                _ghostShatterTimer = Timer(
                  Duration(milliseconds: delay as int),
                  () {
                    if (mounted) {
                      setState(() {
                        for (var block in _ghostEquationState) {
                          if (shatterList.contains(block.id)) {
                            block.animState = 'shatter';
                          }
                        }
                      });
                    }
                  },
                );
              }
            }
          }
        }
      });

      String? mensajeAyuda;

      // Fase 3: Conexión con el Backend si el nivel de ayuda es >= 2
      if (nivelAyuda >= 2) {
        try {
          String eqString = _equationState.map((e) => e.text).join(" ");
          final res = await MathApiService.validarAccion(
            ecuacionActual: eqString,
            accionTexto: option['text'],
            errorType: errorType,
          );
          mensajeAyuda = res['mensaje_ayuda'];
        } catch (e) {
          mensajeAyuda =
              "Recuerda repasar las reglas básicas de las operaciones inversas.";
        }

        if (mounted) {
          setState(() {
            _isProcessingStep = false;
          });
        }
      }

      if (mounted) {
        // Mostrar Ayuda visual escalonada (Fase 3 MVP)
        if (nivelAyuda >= 2 && mensajeAyuda != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    color: Colors.yellowAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dato Clave:\n$mensajeAyuda',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.9),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          );
        }

        int visualDelay = nivelAyuda >= 3
            ? 3500
            : (nivelAyuda >= 2 ? 1500 : 600);

        _errorTimer = Timer(Duration(milliseconds: visualDelay), () {
          if (mounted) {
            setState(() {
              _isErrorState = false;
              _selectedWrongOptionIndex = null;
              _showGhostAnimation = false;
              _ghostShatterTimer?.cancel();
            });
          }
        });
      }
    }
  }

  void _handleNextLevel() {
    setState(() {
      _gameFinished = true;
    });
    widget.onExerciseCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF020B14),
        body: Stack(
          children: [
            // Background Effects
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1),
                  radius: 1.5,
                  colors: [Color(0xFF0A2E4A), Color(0xFF020B14)],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
            Positioned(
              top: -100,
              right: -100,
              child:
                  Container(
                        width: 500,
                        height: 500,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF001A33),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(end: 1.1, duration: 4.seconds)
                      .blurXY(end: 60),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Column(
                        children: [
                          const Text(
                                "Misterios del Álgebra",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              )
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.5, end: 0),
                          const SizedBox(height: 8),
                          Text(
                            currentLevel['title'] as String,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                        ],
                      ),
                      const SizedBox(height: 40),

                      if (!_gameFinished) ...[
                        if (_isTutorialMode && currentTutorialStep != null)
                          _buildTutorialModal()
                        else
                          _buildPracticalGame(),
                      ] else
                        _buildVictoryScreen(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialModal() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1526).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            blurRadius: 50,
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Header Tutorial
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("👨‍🏫", style: TextStyle(fontSize: 32))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: -5, end: 5, duration: 1500.ms),
                  const SizedBox(width: 12),
                  const Text(
                    "MÓDULO TEÓRICO",
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Row(
                children: List.generate(
                  (currentLevel['tutorial'] as List).length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(left: 6),
                    height: 8,
                    width: index == _tutorialStepIndex ? 32 : 8,
                    decoration: BoxDecoration(
                      color: index == _tutorialStepIndex
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF1E2A40),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: index == _tutorialStepIndex
                          ? [
                              const BoxShadow(
                                color: Color(0xFF38BDF8),
                                blurRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: Color(0xFF1E2A40), height: 1),
          ),

          // Content
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 180),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentTutorialStep!['text'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (currentTutorialStep!['equation'] != null) ...[
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF020B14).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: (currentTutorialStep!['equation'] as List).map((
                        blockMap,
                      ) {
                        final block = EquationBlockState.fromMap(blockMap);
                        return EquationBlockWidget(block: block);
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Action Button
          ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: const Color(0xFF020B14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                  shadowColor: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  side: const BorderSide(color: Color(0xFF7DD3FC), width: 2),
                ),
                onPressed: _handleTutorialNext,
                child: Text(
                  _tutorialStepIndex <
                          (currentLevel['tutorial'] as List).length - 1
                      ? 'Siguiente Lección ➡️'
                      : '¡A Practicar! 🚀',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
              .animate(onPlay: (ctrl) => ctrl.repeat())
              .scaleXY(begin: 1.0, end: 1.05, duration: 2.seconds)
              .then()
              .scaleXY(begin: 1.05, end: 1.0, duration: 2.seconds),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildPracticalGame() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 900),
      child: Column(
        children: [
          // Equation Wrap
          Animate(
            key: ValueKey(_isErrorState),
            effects: _isErrorState
                ? const [
                    ShakeEffect(hz: 8, duration: Duration(milliseconds: 500)),
                  ]
                : [],
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showGhostAnimation ? 0.6 : 1.0,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 16,
                  children:
                      (_showGhostAnimation && _ghostEquationState.isNotEmpty
                              ? _ghostEquationState
                              : _equationState)
                          .map(
                            (b) => EquationBlockWidget(
                              block: b,
                              key: ValueKey(b.id + b.animState),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Question text
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Text(
              currentStep['question'] as String,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.4,
                color: currentStep['isVisualExplanation'] == true
                    ? const Color(0xFF38BDF8)
                    : Colors.white,
                shadows: currentStep['isVisualExplanation'] == true
                    ? [const Shadow(color: Color(0xFF38BDF8), blurRadius: 15)]
                    : [],
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 30),

          // Logic Reasoning Panel
          if (currentStep['reasoning'] != null)
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    const Color(0xFFB45309).withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🧠", style: TextStyle(fontSize: 32))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(end: 1.1, duration: 800.ms),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LÓGICA ANALÍTICA:",
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentStep['reasoning'] as String,
                          style: const TextStyle(
                            color: Color(0xFFFCD34D),
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().scale(
              begin: const Offset(0.9, 0.9),
              curve: Curves.easeOutBack,
            ),

          // Action Area
          if (currentStep['isVisualExplanation'] == true)
            // Bouncing dots loader
            SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) =>
                      Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.lightBlueAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.lightBlueAccent,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          )
                          .animate(
                            onPlay: (c) => c.repeat(reverse: true),
                            delay: (index * 200).ms,
                          )
                          .moveY(
                            begin: 0,
                            end: -20,
                            duration: 400.ms,
                            curve: Curves.easeInOut,
                          ),
                ),
              ),
            )
          else if (!isLevelComplete)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: (currentStep['options'] as List).asMap().entries.map((
                entry,
              ) {
                final idx = entry.key;
                final option = entry.value as Map<String, dynamic>;

                final isWrong =
                    _isErrorState && _selectedWrongOptionIndex == idx;
                final isCorrect = _selectedCorrectOptionIndex == idx;

                Color bgColor = const Color(0xFF1B873F);
                Color borderColor = const Color(0xFF24A148);
                Color shadowColor = const Color(0xFF1B873F).withValues(alpha: 0.5);
                double scale = 1.0;

                if (isWrong) {
                  bgColor = Colors.red.shade700;
                  borderColor = Colors.red.shade500;
                  shadowColor = Colors.red.withValues(alpha: 0.8);
                  scale = 0.95;
                } else if (isCorrect) {
                  bgColor = Colors.amber.shade600;
                  borderColor = Colors.amber.shade400;
                  shadowColor = Colors.amber.withValues(alpha: 0.8);
                  scale = 1.05;
                } else if (_showGhostAnimation && option['isCorrect'] == true) {
                  bgColor = const Color(0xFF1B873F).withValues(alpha: 0.5);
                  borderColor = Colors.yellowAccent.withValues(alpha: 0.8);
                  shadowColor = Colors.yellowAccent.withValues(alpha: 0.5);
                }

                Widget btnContent = Container(
                  constraints: const BoxConstraints(minWidth: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius:
                            (isCorrect ||
                                isWrong ||
                                (_showGhostAnimation &&
                                    option['isCorrect'] == true))
                            ? 30
                            : 20,
                      ),
                    ],
                  ),
                  child: Text(
                    (option['text'] ?? '') as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );

                if (_showGhostAnimation && option['isCorrect'] == true) {
                  btnContent = btnContent
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(begin: 0.3, end: 1.0, duration: 600.ms)
                      .scaleXY(begin: 0.95, end: 1.05, duration: 600.ms);
                }

                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 1.0, end: scale),
                  builder: (context, val, child) {
                    return Transform.scale(scale: val, child: child);
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleOptionClick(option, idx),
                      borderRadius: BorderRadius.circular(24),
                      child: btnContent,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 20,
                ),
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF451A03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 15,
                shadowColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFFCD34D), width: 2),
              ),
              onPressed: _handleNextLevel,
              child: Text(
                'Terminar Juego 🏆',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ).animate().scale(
              begin: const Offset(0.5, 0.5),
              curve: Curves.easeOutBack,
              duration: 600.ms,
            ),
        ],
      ),
    );
  }

  Widget _buildVictoryScreen() {
    final necesitaRefuerzo = _sesionController.necesitaPlantillaRefuerzo();
    final antipatron = _sesionController.obtenerAntipatronPrincipal();

    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1526).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF1E2A40)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
            blurRadius: 100,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text("🌌", style: TextStyle(fontSize: 80))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -10, end: 10, duration: 2.seconds),
          const SizedBox(height: 30),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF38BDF8), Color(0xFFFBBF24)],
            ).createShader(bounds),
            child: const Text(
              "¡Mente Maestra Absoluta!",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Has asimilado la teoría de la Academia y la has aplicado a la perfección en la práctica. Ecuaciones lineales, multiversos de raíces y volúmenes cúbicos son tuyos.",
            style: TextStyle(
              color: Color(0xFF8BA3BA),
              fontSize: 20,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            "¡Has dominado el Álgebra!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),

          // MVP Hiperpersonalización: Sugerencia de Refuerzo
          if (necesitaRefuerzo && antipatron != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF59E0B), width: 2),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy, color: Color(0xFFFCD34D)),
                      SizedBox(width: 8),
                      Text(
                        "Sugerencia del Tutor AI",
                        style: TextStyle(
                          color: Color(0xFFFCD34D),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "He notado que el concepto '$antipatron' te dio un poco de batalla. ¿Qué tal un mini-reto rápido para fortalecerlo?",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: const Color(0xFF451A03),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cargando plantilla de refuerzo... (Fase 4 MVP)',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Entrenar Debilidad 💪",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],

          // Fin Sugerencia de Refuerzo
          const SizedBox(height: 80), // Espacio para la barra global
        ],
      ),
    ).animate().fadeIn().scale();
  }
}

class EquationBlockWidget extends StatefulWidget {
  final EquationBlockState block;

  const EquationBlockWidget({super.key, required this.block});

  @override
  State<EquationBlockWidget> createState() => _EquationBlockWidgetState();
}

class _EquationBlockWidgetState extends State<EquationBlockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shatterCtrl;

  @override
  void initState() {
    super.initState();
    _shatterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.block.animState == 'shatter') {
      _shatterCtrl.forward();
    }
  }

  @override
  void didUpdateWidget(covariant EquationBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.animState == 'shatter' &&
        oldWidget.block.animState != 'shatter') {
      _shatterCtrl.forward();
    }
  }

  @override
  void dispose() {
    _shatterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.block.type == 'text' || widget.block.type == 'bracket') {
      Widget w = Text(
        widget.block.text,
        style: TextStyle(
          fontSize: widget.block.type == 'bracket' ? 48 : 40,
          fontWeight: widget.block.type == 'bracket'
              ? FontWeight.w300
              : FontWeight.w900,
          color: widget.block.type == 'bracket'
              ? const Color(0xFF38BDF8)
              : Colors.white,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 10)],
        ),
      );

      if (widget.block.animState == 'shatter') {
        w = w
            .animate()
            .scaleXY(end: 1.5)
            .fadeOut(duration: 800.ms)
            .blurXY(end: 10)
            .shake(hz: 10);
      } else if (widget.block.animState == 'pop') {
        w = w.animate().scale(
          begin: const Offset(0.4, 0.4),
          curve: Curves.easeOutBack,
          duration: 600.ms,
        );
      } else {
        w = w
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: -5,
              end: 5,
              duration: 2.seconds,
              curve: Curves.easeInOut,
            );
      }
      return w;
    }

    Color bgColor = widget.block.type == 'dark'
        ? const Color(0xFF1A1C23)
        : widget.block.type == 'action'
        ? const Color(0xFF0284C7)
        : const Color(0xFF1B873F);
    Color borderColor = widget.block.type == 'dark'
        ? const Color(0xFF2A2D36)
        : widget.block.type == 'action'
        ? const Color(0xFF0369A1)
        : const Color(0xFF24A148);
    Color textCol = widget.block.type == 'dark'
        ? const Color(0xFFF0F2F5)
        : Colors.white;
    Color glowColor = widget.block.type == 'dark'
        ? Colors.black45
        : widget.block.type == 'action'
        ? const Color(0xFF0284C7)
        : const Color(0xFF1B873F);
    List<BoxShadow> shadows = [
      BoxShadow(
        color: glowColor.withValues(alpha: widget.block.type == 'dark' ? 0.4 : 0.8),
        blurRadius: widget.block.type == 'dark' ? 16 : 25,
        offset: const Offset(0, 8),
      ),
    ];

    Widget core = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: shadows,
      ),
      child: Text(
        widget.block.text,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: textCol,
          letterSpacing: -1,
        ),
      ),
    );

    if (widget.block.animState == 'shatter') {
      // Animación de ruptura multi-fragmento: simula romperse en 3 piezas
      // que salen disparadas en diferentes direcciones
      return AnimatedBuilder(
        animation: _shatterCtrl,
        builder: (context, child) {
          final t = _shatterCtrl.value;
          final opacity = (1.0 - t).clamp(0.0, 1.0);
          final shake = t < 0.35 ? (t / 0.35) : 0.0;
          final explode = t > 0.35 ? ((t - 0.35) / 0.65) : 0.0;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Fragmento principal — se desploma hacia abajo
              Transform.translate(
                offset: Offset(0, explode * 120),
                child: Transform.rotate(
                  angle: explode * 0.3,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: 1.0 + shake * 0.08,
                      child: core,
                    ),
                  ),
                ),
              ),
              // Fragmento izquierdo — vuela a la izquierda y arriba
              if (t > 0.35)
                Transform.translate(
                  offset: Offset(-explode * 90, -explode * 60),
                  child: Transform.rotate(
                    angle: -explode * 0.8,
                    child: Opacity(
                      opacity: (opacity * 1.2).clamp(0.0, 1.0),
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Text(
                              widget.block.text,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: textCol,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Fragmento derecho — vuela a la derecha y arriba
              if (t > 0.35)
                Transform.translate(
                  offset: Offset(explode * 90, -explode * 60),
                  child: Transform.rotate(
                    angle: explode * 0.8,
                    child: Opacity(
                      opacity: (opacity * 1.2).clamp(0.0, 1.0),
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerRight,
                          widthFactor: 0.5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Text(
                              widget.block.text,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: textCol,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    } else if (widget.block.animState == 'pop') {
      return core.animate().scale(
        begin: const Offset(0.4, 0.4),
        curve: Curves.easeOutBack,
        duration: 600.ms,
      );
    } else {
      return core
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: -5,
            end: 5,
            duration: 2.seconds,
            delay: Duration(
              milliseconds: widget.block.text.hashCode.abs() % 500,
            ),
          );
    }
  }
}
