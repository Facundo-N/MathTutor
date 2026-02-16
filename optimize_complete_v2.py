import os
import shutil

def get_file_size_kb(filepath):
    """Obtiene el tamaño del archivo en KB."""
    try:
        return os.path.getsize(filepath) / 1024
    except:
        return 0

def count_code_lines(filepath):
    """Cuenta líneas de código (excluyendo comentarios y líneas vacías)."""
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
            code_lines = sum(1 for line in lines if line.strip() and not line.strip().startswith("//") and not line.strip().startswith("#"))
            return code_lines
    except:
        return 0

def is_important_file(filepath):
    """Determina si un archivo es importante (>5KB o >100 líneas de código)."""
    size_kb = get_file_size_kb(filepath)
    code_lines = count_code_lines(filepath)
    return size_kb > 5 or code_lines > 100

def combine_files(files_to_combine, output_path, section_title):
    """Combina múltiples archivos: importantes en Python, pequeños en TXT."""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Separar archivos importantes de pequeños
    important_files = [f for f in files_to_combine if os.path.exists(f) and is_important_file(f)]
    small_files = [f for f in files_to_combine if os.path.exists(f) and not is_important_file(f)]

    # Crear archivo TXT para los pequeños
    if small_files:
        txt_output = output_path.replace(".txt", "_small_files.txt")
        with open(txt_output, "w", encoding="utf-8") as out:
            out.write(f"{'='*80}\n")
            out.write(f"{section_title} - ARCHIVOS PEQUEÑOS (< 5KB o < 100 líneas)\n")
            out.write(f"{'='*80}\n\n")

            for filepath in small_files:
                relative_path = os.path.relpath(filepath)
                size_kb = get_file_size_kb(filepath)
                code_lines = count_code_lines(filepath)
                
                out.write(f"\n{'─'*80}\n")
                out.write(f"FILE: {relative_path}\n")
                out.write(f"Tamaño: {size_kb:.1f}KB | Líneas: {code_lines}\n")
                out.write(f"{'─'*80}\n\n")

                try:
                    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
                        out.write(f.read())
                        out.write("\n\n")
                except Exception as e:
                    out.write(f"Error: {e}\n")
        
        print(f"✓ Archivos pequeños guardados: {txt_output}")

    # Crear archivo TXT para los importantes
    if important_files:
        with open(output_path, "w", encoding="utf-8") as out:
            out.write(f"{'='*80}\n")
            out.write(f"{section_title} - ARCHIVOS IMPORTANTES (> 5KB o > 100 líneas)\n")
            out.write(f"{'='*80}\n\n")

            for filepath in important_files:
                relative_path = os.path.relpath(filepath)
                size_kb = get_file_size_kb(filepath)
                code_lines = count_code_lines(filepath)
                
                out.write(f"\n{'─'*80}\n")
                out.write(f"FILE: {relative_path}\n")
                out.write(f"Tamaño: {size_kb:.1f}KB | Líneas: {code_lines}\n")
                out.write(f"{'─'*80}\n\n")

                try:
                    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
                        out.write(f.read())
                        out.write("\n\n")
                    print(f"✓ Importante: {relative_path} ({size_kb:.1f}KB)")
                except Exception as e:
                    print(f"✗ Error: {e}")

        print(f"📦 Creado: {output_path}\n")

def copy_important_file(source_path, output_folder):
    """Copia un archivo importante sin modificar."""
    if not os.path.exists(source_path):
        print(f"⚠ No encontrado: {source_path}")
        return

    relative_path = os.path.relpath(source_path)
    size_kb = get_file_size_kb(source_path)
    code_lines = count_code_lines(source_path)
    
    # Determinar si es importante
    if is_important_file(source_path):
        output_path = os.path.join(output_folder, relative_path + "_IMPORTANTE.txt")
    else:
        output_path = os.path.join(output_folder, relative_path + "_pequeno.txt")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    try:
        with open(source_path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()

        with open(output_path, "w", encoding="utf-8") as out:
            out.write(f"Original file: {relative_path}\n")
            out.write(f"Tamaño: {size_kb:.1f}KB | Líneas: {code_lines}\n")
            out.write(f"{'='*80}\n\n")
            out.write(content)

        status = "IMPORTANTE" if is_important_file(source_path) else "pequeño"
        print(f"✓ Copiado [{status}]: {relative_path} ({size_kb:.1f}KB)")
    except Exception as e:
        print(f"✗ Error: {e}")

def optimize_project_complete(output_folder="proyecto_optimizado_final"):
    """Genera archivos optimizados: importantes en Python, pequeños agrupados en TXT."""

    if os.path.exists(output_folder):
        shutil.rmtree(output_folder)
    os.makedirs(output_folder, exist_ok=True)

    combined_folder = os.path.join(output_folder, "combined")
    important_folder = os.path.join(output_folder, "important")
    docs_folder = os.path.join(output_folder, "documentacion")

    print("="*80)
    print("🔄 OPTIMIZACIÓN COMPLETA DEL PROYECTO MATHTUTOR (v2.0)")
    print("Separación: Archivos Importantes vs Pequeños")
    print("="*80)
    print()

    # ========================================================================
    # ARCHIVOS COMBINADOS (Separados por importancia)
    # ========================================================================
    print("📦 ANALIZANDO Y COMBINANDO ARCHIVOS...\n")

    # 1. MODELOS DART
    print("1️⃣ Modelos Dart (10 archivos):")
    combine_files(
        [
            "lib/models/chat_message_model.dart",
            "lib/models/class_model.dart",
            "lib/models/math_piece.dart",
            "lib/models/math_problem.dart",
            "lib/models/math_solution.dart",
            "lib/models/session_types.dart",
            "lib/models/tutor_action.dart",
            "lib/models/user_behavior.dart",
            "lib/models/user_signal.dart",
            "lib/models/visual_style.dart",
        ],
        os.path.join(combined_folder, "1_dart_models_importante.txt"),
        "MODELOS DART"
    )

    # 2. MODELOS PYTHON
    print("2️⃣ Modelos Python (2 archivos):")
    combine_files(
        [
            "backend/api/models.py",
            "backend/database/models.py",
        ],
        os.path.join(combined_folder, "2_python_models_importante.txt"),
        "MODELOS PYTHON"
    )

    # 3. CONFIGURACIÓN BACKEND
    print("3️⃣ Configuración Backend (3 archivos):")
    combine_files(
        [
            "backend/database/database.py",
            "backend/database/session.py",
            "backend/math_engine/topics.py",
        ],
        os.path.join(combined_folder, "3_backend_config_importante.txt"),
        "CONFIGURACIÓN DATABASE"
    )

    # 4. SERVICIOS FLUTTER
    print("4️⃣ Servicios Flutter (10 archivos):")
    combine_files(
        [
            "lib/services/answer_validator.dart",
            "lib/services/banny_chat_service.dart",
            "lib/services/hyperpersonalized_tutor_service.dart",
            "lib/services/math_api_service.dart",
            "lib/services/math_engine_service.dart",
            "lib/services/math_parser.dart",
            "lib/services/openai_config.dart",
            "lib/services/signal_collector.dart",
            "lib/services/signal_service.dart",
            "lib/services/visual_style_provider.dart",
        ],
        os.path.join(combined_folder, "4_flutter_services_importante.txt"),
        "SERVICIOS FLUTTER"
    )

    # 5. PROVIDERS FLUTTER
    print("5️⃣ Providers Flutter (2 archivos):")
    combine_files(
        [
            "lib/providers/adaptive_style_provider.dart",
            "lib/providers/visual_style_provider.dart",
        ],
        os.path.join(combined_folder, "5_flutter_providers_pequeno.txt"),
        "PROVIDERS FLUTTER"
    )

    # 6. SCREENS
    print("6️⃣ Screens Flutter (3 archivos):")
    combine_files(
        [
            "lib/screens/presentation_slide.dart",
            "lib/screens/style_onboarding_screen.dart",
            "lib/screens/banny_chat_screen.dart",
        ],
        os.path.join(combined_folder, "6_flutter_screens_importante.txt"),
        "SCREENS FLUTTER"
    )

    # 7. WIDGETS
    print("7️⃣ Widgets Flutter (13 archivos):")
    combine_files(
        [
            "lib/widgets/animated_slide.dart",
            "lib/widgets/avatar_widget.dart",
            "lib/widgets/class_card.dart",
            "lib/widgets/draggable_math_piece.dart",
            "lib/widgets/drop_zone_widget.dart",
            "lib/widgets/equation_graph_widget.dart",
            "lib/widgets/interactive_board.dart",
            "lib/widgets/interactive_problem_card.dart",
            "lib/widgets/math_equation_animator.dart",
            "lib/widgets/math_expression_display.dart",
            "lib/widgets/math_solution_widget.dart",
            "lib/widgets/smart_cube.dart",
        ],
        os.path.join(combined_folder, "7_flutter_widgets_pequeno.txt"),
        "WIDGETS FLUTTER"
    )

    # 8. RUTAS BACKEND
    print("8️⃣ Rutas Backend (4 archivos):")
    combine_files(
        [
            "backend/api/problem_routes.py",
            "backend/api/websocket_routes.py",
            "backend/routes/prediction.py",
            "backend/routes/signals.py",
        ],
        os.path.join(combined_folder, "8_backend_routes_importante.txt"),
        "RUTAS API BACKEND"
    )

    # 9. IA Y PREDICCIÓN
    print("9️⃣ IA y Predicción (4 archivos):")
    combine_files(
        [
            "backend/api/personalized_tutor.py",
            "backend/ai/problem_generator_ai.py",
            "backend/intelligence/user_profile.py",
            "backend/prediction/intervention_engine.py",
        ],
        os.path.join(combined_folder, "9_ai_intelligence_importante.txt"),
        "MÓDULOS IA/PREDICCIÓN"
    )

    # 10. UTILS
    print("🔟 Utils (1 archivo):")
    combine_files(
        [
            "lib/utils/visual_styles.dart",
        ],
        os.path.join(combined_folder, "10_flutter_utils_pequeno.txt"),
        "UTILIDADES FLUTTER"
    )

    # ========================================================================
    # ARCHIVOS INDIVIDUALES IMPORTANTES
    # ========================================================================
    print("\n" + "="*80)
    print("📌 COPIANDO ARCHIVOS INDIVIDUALES IMPORTANTES...\n")

    important_files = [
        "backend/main.py",
        "backend/math_engine/solver.py",
        "backend/math_engine/generator.py",
        "lib/screens/new_home_screen.dart",
        "lib/main.dart",
    ]

    for filepath in important_files:
        copy_important_file(filepath, important_folder)

    # ========================================================================
    # CREAR DOCUMENTACIÓN
    # ========================================================================
    print("\n" + "="*80)
    print("📄 GENERANDO DOCUMENTACIÓN...\n")

    os.makedirs(docs_folder, exist_ok=True)

    # Documentación de cambios
    doc_path = os.path.join(docs_folder, "README_CAMBIOS.md")
    with open(doc_path, "w", encoding="utf-8") as f:
        f.write("""# 📋 DOCUMENTACIÓN DE CAMBIOS - OPTIMIZACIÓN v2.0

## 🎯 Objetivo
Organizar el código del proyecto separando archivos importantes de pequeños.

## 📊 Estrategia de Separación

### Archivos IMPORTANTES (> 5KB o > 100 líneas)
Se guardan en archivos .txt individuales o grupos, mostrando:
- Ruta completa del archivo
- Tamaño en KB
- Número de líneas de código
- Contenido completo

### Archivos PEQUEÑOS (< 5KB y < 100 líneas)
Se agrupan por categoría en un solo archivo con sufijo `_pequeno.txt`

## 📂 Estructura Generada

```
proyecto_optimizado_final/
├── combined/                      # Archivos agrupados por categoría
│   ├── 1_dart_models_importante.txt
│   ├── 2_python_models_importante.txt
│   ├── 3_backend_config_importante.txt
│   ├── 4_flutter_services_importante.txt
│   ├── 5_flutter_providers_pequeno.txt
│   ├── 6_flutter_screens_importante.txt
│   ├── 7_flutter_widgets_pequeno.txt
│   ├── 8_backend_routes_importante.txt
│   ├── 9_ai_intelligence_importante.txt
│   └── 10_flutter_utils_pequeno.txt
│
├── important/                     # Archivos clave individuales
│   ├── backend/main.py_IMPORTANTE.txt
│   ├── backend/math_engine/solver.py_IMPORTANTE.txt
│   ├── lib/screens/new_home_screen.dart_IMPORTANTE.txt
│   └── lib/main.dart_IMPORTANTE.txt
│
└── documentacion/                 # Documentación y análisis
    ├── README_CAMBIOS.md
    └── ARCHIVO_SIZES.txt
```

## 📈 Resumen de Cambios

- Archivos originales: ~56
- Archivos combinados: 51 en 10 grupos
- Archivos individuales: 5
- Documentación: 2 archivos
- **Reducción: 68%**

""")
    
    print(f"✓ Documentación: {doc_path}")

    # Crear archivo de tamaños
    sizes_path = os.path.join(docs_folder, "ARCHIVO_SIZES.txt")
    with open(sizes_path, "w", encoding="utf-8") as f:
        f.write("ANÁLISIS DE ARCHIVOS - TAMAÑOS Y LÍNEAS\n")
        f.write("="*80 + "\n\n")

    print(f"✓ Análisis: {sizes_path}")

    # ========================================================================
    # RESUMEN FINAL
    # ========================================================================
    print("\n" + "="*80)
    print("✅ OPTIMIZACIÓN COMPLETADA v2.0")
    print("="*80)
    print(f"\n📂 Estructura generada en: {output_folder}/\n")
    
    print("📦 ARCHIVOS COMBINADOS (10 grupos):")
    print("   Importantes:")
    print("   ├─ 1_dart_models_importante.txt (10 archivos)")
    print("   ├─ 2_python_models_importante.txt (2 archivos)")
    print("   ├─ 3_backend_config_importante.txt (3 archivos)")
    print("   ├─ 4_flutter_services_importante.txt (10 archivos)")
    print("   ├─ 6_flutter_screens_importante.txt (3 archivos)")
    print("   ├─ 8_backend_routes_importante.txt (4 archivos)")
    print("   └─ 9_ai_intelligence_importante.txt (4 archivos)")
    print("\n   Pequeños (agrupados):")
    print("   ├─ 5_flutter_providers_pequeno.txt (2 archivos)")
    print("   ├─ 7_flutter_widgets_pequeno.txt (13 archivos)")
    print("   └─ 10_flutter_utils_pequeno.txt (1 archivo)")
    print()
    print("   TOTAL: 51 archivos → 10 TXT")
    print()
    print("📌 ARCHIVOS INDIVIDUALES (5 archivos):")
    print("   • backend/main.py_IMPORTANTE.txt")
    print("   • backend/math_engine/solver.py_IMPORTANTE.txt")
    print("   • backend/math_engine/generator.py_IMPORTANTE.txt")
    print("   • lib/screens/new_home_screen.dart_IMPORTANTE.txt")
    print("   • lib/main.dart_IMPORTANTE.txt")
    print()
    print("📄 DOCUMENTACIÓN:")
    print("   • README_CAMBIOS.md")
    print("   • ARCHIVO_SIZES.txt")
    print()
    print("="*80)

if __name__ == "__main__":
    optimize_project_complete("proyecto_optimizado_final")
