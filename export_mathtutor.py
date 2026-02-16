import os
import shutil

def combine_files(files_to_combine, output_path, section_title):
    """Combina múltiples archivos en uno solo."""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, "w", encoding="utf-8") as out:
        out.write(f"{'='*80}\n")
        out.write(f"{section_title}\n")
        out.write(f"{'='*80}\n\n")

        for filepath in files_to_combine:
            if not os.path.exists(filepath):
                print(f"⚠ No encontrado: {filepath}")
                continue

            relative_path = os.path.relpath(filepath)
            out.write(f"\n{'─'*80}\n")
            out.write(f"FILE: {relative_path}\n")
            out.write(f"{'─'*80}\n\n")

            try:
                with open(filepath, "r", encoding="utf-8", errors="replace") as f:
                    out.write(f.read())
                    out.write("\n\n")
                print(f"✓ {relative_path}")
            except Exception as e:
                print(f"✗ Error: {e}")

    print(f"📦 Creado: {output_path}\n")

def copy_important_file(source_path, output_folder):
    """Copia un archivo importante sin modificar."""
    if not os.path.exists(source_path):
        print(f"⚠ No encontrado: {source_path}")
        return

    relative_path = os.path.relpath(source_path)
    output_path = os.path.join(output_folder, relative_path + ".txt")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    try:
        with open(source_path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()

        with open(output_path, "w", encoding="utf-8") as out:
            out.write(f"Original file: {relative_path}\n")
            out.write(f"{'='*80}\n\n")
            out.write(content)

        print(f"✓ {relative_path}")
    except Exception as e:
        print(f"✗ Error: {e}")

def optimize_mathtutor_project(output_folder="mathtutor_exportado"):
    """
    Exporta el proyecto MathTutor según la organización del usuario:
    - DOCUMENTACION.txt
    - ARCHIVOS_IMPORTANTES.txt
    - ARCHIVOS_PEQUENOS.txt (combinados)
    """

    if os.path.exists(output_folder):
        shutil.rmtree(output_folder)
    os.makedirs(output_folder, exist_ok=True)

    combined_folder = os.path.join(output_folder, "combined")
    important_folder = os.path.join(output_folder, "important")
    docs_folder = os.path.join(output_folder, "docs")

    print("="*80)
    print("🚀 EXPORTACIÓN PROYECTO MATHTUTOR")
    print("="*80)
    print()

    # ========================================================================
    # 1. COMBINAR ARCHIVOS PEQUEÑOS
    # ========================================================================
    print("📦 PASO 1: Combinando archivos pequeños...\n")

    # A. FLUTTER WIDGETS (12 archivos)
    print("1️⃣ Flutter Widgets (12 archivos):")
    combine_files(
        [
            "lib/widgets/class_card.dart",
            "lib/widgets/draggable_math_piece.dart",
            "lib/widgets/avatar_widget.dart",
            "lib/widgets/animated_slide.dart",
            "lib/widgets/smart_cube.dart",
            "lib/widgets/math_solution_widget.dart",
            "lib/widgets/math_expression_display.dart",
            "lib/widgets/math_equation_animator.dart",
            "lib/widgets/interactive_problem_card.dart",
            "lib/widgets/interactive_board.dart",
            "lib/widgets/equation_graph_widget.dart",
            "lib/widgets/drop_zone_widget.dart",
        ],
        os.path.join(combined_folder, "flutter_widgets_combined.txt"),
        "FLUTTER WIDGETS COMBINADOS"
    )

    # B. FLUTTER UTILS (1 archivo)
    print("2️⃣ Flutter Utils (1 archivo):")
    combine_files(
        ["lib/utils/visual_styles.dart"],
        os.path.join(combined_folder, "flutter_utils_combined.txt"),
        "FLUTTER UTILS"
    )

    # C. FLUTTER SERVICIOS PEQUEÑOS (2 archivos)
    print("3️⃣ Flutter Servicios (2 archivos):")
    combine_files(
        [
            "lib/services/visual_style_provider.dart",
            "lib/services/signal_service.dart",
        ],
        os.path.join(combined_folder, "flutter_services_light_combined.txt"),
        "FLUTTER SERVICIOS LIGEROS"
    )

    # D. FLUTTER SCREENS ONBOARDING (2 archivos)
    print("4️⃣ Flutter Screens Onboarding (2 archivos):")
    combine_files(
        [
            "lib/screens/style_onboarding_screen.dart",
            "lib/screens/presentation_slide.dart",
        ],
        os.path.join(combined_folder, "flutter_screens_onboarding_combined.txt"),
        "PANTALLAS DE ONBOARDING"
    )

    # E. BACKEND ROUTES (4 archivos)
    print("5️⃣ Backend Routes (4 archivos):")
    combine_files(
        [
            "backend/routes/__init__.py",
            "backend/routes/prediction.py",
            "backend/routes/signals.py",
            "backend/routes/websocket.py",
        ],
        os.path.join(combined_folder, "backend_routes_combined.txt"),
        "BACKEND ROUTES"
    )

    # F. BACKEND DATABASE (3 archivos)
    print("6️⃣ Backend Database (3 archivos):")
    combine_files(
        [
            "backend/database/__init__.py",
            "backend/database/models.py",
            "backend/database/session.py",
        ],
        os.path.join(combined_folder, "backend_database_combined.txt"),
        "BACKEND DATABASE"
    )

    # G. BACKEND API (3 archivos)
    print("7️⃣ Backend API (3 archivos):")
    combine_files(
        [
            "backend/api/__init__.py",
            "backend/api/models.py",
            "backend/api/personalized_tutor.py",
        ],
        os.path.join(combined_folder, "backend_api_combined.txt"),
        "BACKEND API MODELS"
    )

    # H. BACKEND MATH ENGINE (2 archivos)
    print("8️⃣ Backend Math Engine (2 archivos):")
    combine_files(
        [
            "backend/math_engine/__init__.py",
            "backend/math_engine/topics.py",
        ],
        os.path.join(combined_folder, "backend_math_engine_config_combined.txt"),
        "BACKEND MATH ENGINE CONFIG"
    )

    # I. BACKEND INTELIGENCIA (3 archivos)
    print("9️⃣ Backend Inteligencia (3 archivos):")
    combine_files(
        [
            "backend/services/__init__.py",
            "backend/intelligence/user_profile.py",
            "backend/prediction/intervention_engine.py",
        ],
        os.path.join(combined_folder, "backend_intelligence_combined.txt"),
        "BACKEND INTELIGENCIA Y PREDICCIÓN"
    )

    # ========================================================================
    # 2. COPIAR ARCHIVOS IMPORTANTES (NO COMBINAR)
    # ========================================================================
    print("\n" + "="*80)
    print("📌 PASO 2: Copiando archivos importantes...\n")

    important_files = [
        # Flutter importantes
        "lib/main.dart",
        "lib/services/banny_chat_service.dart",
        "lib/services/openai_config.dart",
        "lib/screens/banny_chat_screen.dart",
        "lib/screens/new_home_screen.dart",

        # Backend importantes
        "backend/main.py",
        "backend/api/websocket_routes.py",
        "backend/ai/problem_generator_ai.py",
        "backend/api/problem_routes.py",
        "backend/database/database.py",
        "backend/math_engine/generator.py",
        "backend/math_engine/solver.py",

        # Testing
        "backend/test_websocket.py",
        "backend/test_openai_setup.py",

        # Configuración
        "pubspec.yaml",
        "backend/requirements.txt",
        "backend/.env",
    ]

    print("Archivos críticos:")
    for filepath in important_files:
        copy_important_file(filepath, important_folder)

    # ========================================================================
    # 3. COPIAR DOCUMENTACIÓN
    # ========================================================================
    print("\n" + "="*80)
    print("📄 PASO 3: Copiando documentación...\n")

    doc_files = [
        "IMPLEMENTACION_COMPLETADA.md",
        "OPENAI_FUNCIONANDO.txt",
        "QUICK_START.md",
        "SETUP_OPENAI.md",
        "VERIFICACION_FINAL.md",
    ]

    print("Documentación:")
    for doc in doc_files:
        if os.path.exists(doc):
            copy_important_file(doc, docs_folder)

    # ========================================================================
    # RESUMEN FINAL
    # ========================================================================
    print("\n" + "="*80)
    print("✅ EXPORTACIÓN COMPLETADA")
    print("="*80)
    print(f"\n📂 Estructura generada en: {output_folder}/\n")

    print("📦 ARCHIVOS COMBINADOS (9 grupos):")
    print("   ├─ flutter_widgets_combined.txt              (12 archivos)")
    print("   ├─ flutter_utils_combined.txt                (1 archivo)")
    print("   ├─ flutter_services_light_combined.txt       (2 archivos)")
    print("   ├─ flutter_screens_onboarding_combined.txt   (2 archivos)")
    print("   ├─ backend_routes_combined.txt               (4 archivos)")
    print("   ├─ backend_database_combined.txt             (3 archivos)")
    print("   ├─ backend_api_combined.txt                  (3 archivos)")
    print("   ├─ backend_math_engine_config_combined.txt   (2 archivos)")
    print("   └─ backend_intelligence_combined.txt         (3 archivos)")
    print()
    print("   TOTAL COMBINADOS: 32 archivos → 9 archivos")
    print()

    print("📌 ARCHIVOS IMPORTANTES (17 archivos):")
    print("   • Flutter: main.dart, banny_chat_service.dart, openai_config.dart")
    print("   • Screens: banny_chat_screen.dart, new_home_screen.dart")
    print("   • Backend: main.py, websocket_routes.py, problem_generator_ai.py")
    print("   • Math: generator.py, solver.py, problem_routes.py, database.py")
    print("   • Testing: test_websocket.py, test_openai_setup.py")
    print("   • Config: pubspec.yaml, requirements.txt, .env")
    print()

    print("📄 DOCUMENTACIÓN (5 archivos):")
    print("   • IMPLEMENTACION_COMPLETADA.md")
    print("   • OPENAI_FUNCIONANDO.txt")
    print("   • QUICK_START.md")
    print("   • SETUP_OPENAI.md")
    print("   • VERIFICACION_FINAL.md")
    print()

    print("📊 RESUMEN:")
    print(f"   • Archivos originales: ~75")
    print(f"   • Archivos combinados: 9 (32 archivos en 9)")
    print(f"   • Archivos importantes: 17")
    print(f"   • Documentación: 5")
    print(f"   • TOTAL FINAL: 31 archivos (reducción del 59%)")
    print()
    print("="*80)
    print("💡 Siguiente paso: Subir carpeta '{output_folder}/' al Space")
    print("="*80)

if __name__ == "__main__":
    optimize_mathtutor_project("mathtutor_exportado")
