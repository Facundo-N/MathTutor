"""
MathTutor Flask API
Servidor backend para conectar Flutter con el servicio matematico Python
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import re
from math_service import (
    MathTutorAPI,
    PrimariaService,
    SecundariaService,
    UniversidadService
)

app = Flask(__name__)
CORS(app)

math_api = MathTutorAPI()

@app.route('/health', methods=['GET'])
def health_check():
    """Verifica que el servidor esta funcionando"""
    return jsonify({
        'status': 'ok',
        'message': 'MathTutor API funcionando correctamente',
        'version': '1.0.0'
    })

@app.route('/resolver', methods=['POST'])
def resolver():
    """Resuelve un problema matematico"""
    try:
        data = request.get_json()
        expresion = data.get('expresion', '')
        nivel = data.get('nivel', 'auto')

        if not expresion:
            return jsonify({'error': 'Expresion vacia'}), 400

        if nivel == 'auto':
            nivel = _detectar_nivel(expresion)

        problema = _resolver_por_nivel(expresion, nivel)

        if problema:
            return jsonify({
                'success': True,
                'expresion': problema.expression,
                'solucion': problema.solution,
                'pasos': problema.steps,
                'dificultad': problema.difficulty,
                'tema': problema.topic,
                'pistas': problema.hints
            })
        else:
            return jsonify({
                'success': False,
                'error': 'No se pudo resolver la expresion'
            }), 400

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/generar-ejercicio', methods=['POST'])
def generar_ejercicio():
    """Genera un ejercicio aleatorio"""
    try:
        data = request.get_json()
        nivel = data.get('nivel', 'primaria')
        tema = data.get('tema', 'suma')
        dificultad = data.get('dificultad', 'medio')

        if nivel == 'primaria':
            ejercicios = PrimariaService.generar_ejercicios_aleatorios(
                tema, cantidad=1, dificultad=dificultad
            )
            if ejercicios.problems:
                problema = ejercicios.problems[0]
                return jsonify({
                    'success': True,
                    'expresion': problema.expression,
                    'tema': problema.topic,
                    'dificultad': problema.difficulty,
                    'pistas': problema.hints
                })

        return jsonify({'error': 'Nivel no soportado'}), 400

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/verificar-respuesta', methods=['POST'])
def verificar_respuesta():
    """Verifica si una respuesta es correcta"""
    try:
        data = request.get_json()
        expresion = data.get('expresion', '')
        respuesta_usuario = data.get('respuesta_usuario', '')

        nivel = _detectar_nivel(expresion)
        problema = _resolver_por_nivel(expresion, nivel)

        if not problema:
            return jsonify({'error': 'No se pudo resolver'}), 400

        correcto = str(problema.solution).strip() == str(respuesta_usuario).strip()

        return jsonify({
            'correcto': correcto,
            'solucion_correcta': problema.solution,
            'respuesta_usuario': respuesta_usuario,
            'pasos': problema.steps if not correcto else ['Correcto!'],
            'pistas': problema.hints if not correcto else []
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/primaria/ejercicios', methods=['GET'])
def primaria_ejercicios():
    """Obtiene ejercicios de primaria"""
    tema = request.args.get('tema', 'suma')
    cantidad = int(request.args.get('cantidad', 5))
    dificultad = request.args.get('dificultad', 'medio')

    ejercicios = PrimariaService.generar_ejercicios_aleatorios(
        tema, cantidad, dificultad
    )

    return jsonify({
        'nivel': 'primaria',
        'tema': tema,
        'cantidad': len(ejercicios.problems),
        'ejercicios': [
            {
                'expresion': p.expression,
                'pistas': p.hints
            } for p in ejercicios.problems
        ]
    })

@app.route('/secundaria/ecuacion-lineal', methods=['POST'])
def secundaria_ecuacion_lineal():
    """Resuelve ecuacion lineal: ax + b = c"""
    data = request.get_json()
    a = float(data.get('a', 1))
    b = float(data.get('b', 0))
    c = float(data.get('c', 0))

    problema = SecundariaService.ecuacion_lineal(a, b, c)

    return jsonify({
        'expresion': problema.expression,
        'solucion': problema.solution,
        'pasos': problema.steps,
        'pistas': problema.hints
    })

@app.route('/secundaria/ecuacion-cuadratica', methods=['POST'])
def secundaria_ecuacion_cuadratica():
    """Resuelve ecuacion cuadratica: ax² + bx + c = 0"""
    data = request.get_json()
    a = float(data.get('a', 1))
    b = float(data.get('b', 0))
    c = float(data.get('c', 0))

    problema = SecundariaService.ecuacion_cuadratica(a, b, c)

    return jsonify({
        'expresion': problema.expression,
        'solucion': problema.solution,
        'pasos': problema.steps,
        'pistas': problema.hints
    })

@app.route('/secundaria/trigonometria', methods=['POST'])
def secundaria_trigonometria():
    """Calcula funciones trigonometricas"""
    data = request.get_json()
    angulo = float(data.get('angulo', 0))
    funcion = data.get('funcion', 'sin')
    en_grados = data.get('en_grados', True)

    problema = SecundariaService.trigonometria(angulo, funcion, en_grados)

    return jsonify({
        'expresion': problema.expression,
        'solucion': problema.solution,
        'pasos': problema.steps
    })

@app.route('/universidad/derivada', methods=['POST'])
def universidad_derivada():
    """Calcula derivada de polinomio"""
    data = request.get_json()
    coeficientes = data.get('coeficientes', [1, 0])

    problema = UniversidadService.derivada_polinomial(coeficientes)

    return jsonify({
        'expresion': problema.expression,
        'solucion': problema.solution,
        'pasos': problema.steps,
        'pistas': problema.hints
    })

@app.route('/universidad/integral', methods=['POST'])
def universidad_integral():
    """Calcula integral de polinomio"""
    data = request.get_json()
    coeficientes = data.get('coeficientes', [1, 0])

    problema = UniversidadService.integral_polinomial(coeficientes)

    return jsonify({
        'expresion': problema.expression,
        'solucion': problema.solution,
        'pasos': problema.steps,
        'pistas': problema.hints
    })

@app.route('/universidad/matriz-determinante', methods=['POST'])
def universidad_determinante():
    """Calcula determinante de matriz"""
    data = request.get_json()
    matriz = data.get('matriz', [[1, 0], [0, 1]])

    problema = UniversidadService.matriz_determinante(matriz)

    return jsonify({
        'expresion': problema.expression,
        'solucion': problema.solution,
        'pasos': problema.steps
    })

def _detectar_nivel(expresion: str) -> str:
    """Detecta el nivel educativo de una expresion"""
    expr = expresion.lower()

    if any(palabra in expr for palabra in ['derivada', 'integral', 'limite', 'matriz']):
        return 'universidad'

    if any(operador in expr for operador in ['x²', 'x^2', 'sen', 'cos', 'tan']):
        return 'secundaria'

    if 'x' in expr and any(op in expr for op in ['=', '+', '-']):
        return 'secundaria'

    return 'primaria'

def _resolver_por_nivel(expresion: str, nivel: str):
    """Resuelve una expresion segun su nivel"""

    if nivel == 'primaria':
        match = re.match(r'(\d+)\s*\+\s*(\d+)', expresion)
        if match:
            return PrimariaService.suma(int(match.group(1)), int(match.group(2)))

        match = re.match(r'(\d+)\s*-\s*(\d+)', expresion)
        if match:
            return PrimariaService.resta(int(match.group(1)), int(match.group(2)))

        match = re.match(r'(\d+)\s*[*×x]\s*(\d+)', expresion)
        if match:
            return PrimariaService.multiplicacion(int(match.group(1)), int(match.group(2)))

        match = re.match(r'(\d+)\s*[/÷]\s*(\d+)', expresion)
        if match:
            return PrimariaService.division(int(match.group(1)), int(match.group(2)))

    elif nivel == 'secundaria':
        match = re.match(r'(\d+)x\s*([+-])\s*(\d+)\s*=\s*(\d+)', expresion)
        if match:
            a = float(match.group(1))
            b = float(match.group(3))
            if match.group(2) == '-':
                b = -b
            c = float(match.group(4))
            return SecundariaService.ecuacion_lineal(a, b, c)

        match = re.match(r'(\d+)x[²2]\s*([+-])\s*(\d+)x\s*([+-])\s*(\d+)\s*=\s*0', expresion)
        if match:
            a = float(match.group(1))
            b = float(match.group(3))
            if match.group(2) == '-':
                b = -b
            c = float(match.group(5))
            if match.group(4) == '-':
                c = -c
            return SecundariaService.ecuacion_cuadratica(a, b, c)

    return None

if __name__ == '__main__':
    print("=" * 70)
    print("      MathTutor API iniciada")
    print("=" * 70)
    print()
    print("Servidor corriendo en http://localhost:5000")
    print()
    print("Endpoints disponibles:")
    print("  GET  /health")
    print("  POST /resolver")
    print("  POST /generar-ejercicio")
    print("  POST /verificar-respuesta")
    print("  GET  /primaria/ejercicios")
    print("  POST /secundaria/ecuacion-lineal")
    print("  POST /secundaria/ecuacion-cuadratica")
    print("  POST /universidad/derivada")
    print("  POST /universidad/integral")
    print()
    print("=" * 70)
    print("Listo para recibir requests desde Flutter")
    print("=" * 70)
    print()

    app.run(debug=True, host='0.0.0.0', port=5000)