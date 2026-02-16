import os
import json

def analyze_project():
    """Analiza el proyecto y separa archivos por importancia."""
    
    # Configuración
    lib_folder = "lib"
    backend_folder = "backend"
    
    important_files = []  # > 5KB o > 100 líneas
    small_files = []      # < 5KB y < 100 líneas
    
    def get_file_size_kb(filepath):
        try:
            return os.path.getsize(filepath) / 1024
        except:
            return 0
    
    def count_code_lines(filepath):
        try:
            with open(filepath, "r", encoding="utf-8", errors="replace") as f:
                lines = f.readlines()
                code_lines = sum(1 for line in lines if line.strip() and not line.strip().startswith("//") and not line.strip().startswith("#"))
                return code_lines
        except:
            return 0
    
    def is_important(filepath):
        size_kb = get_file_size_kb(filepath)
        lines = count_code_lines(filepath)
        return size_kb > 5 or lines > 100
    
    # Scan lib folder
    for root, dirs, files in os.walk(lib_folder):
        for file in files:
            if file.endswith((".dart", ".txt")):
                filepath = os.path.join(root, file)
                if is_important(filepath):
                    important_files.append(filepath)
                else:
                    small_files.append(filepath)
    
    # Scan backend folder
    for root, dirs, files in os.walk(backend_folder):
        # Skip __pycache__ and build folders
        dirs[:] = [d for d in dirs if d not in ['__pycache__', 'build', '.pytest_cache']]
        
        for file in files:
            if file.endswith(".py"):
                filepath = os.path.join(root, file)
                if is_important(filepath):
                    important_files.append(filepath)
                else:
                    small_files.append(filepath)
    
    # Create output files
    os.makedirs("analisis_proyecto", exist_ok=True)
    
    # 1. ARCHIVOS PEQUEÑOS
    with open("analisis_proyecto/archivos_pequenos.txt", "w", encoding="utf-8") as f:
        f.write("=" * 80 + "\n")
        f.write("ARCHIVOS PEQUEÑOS (< 5KB o < 100 líneas de código)\n")
        f.write("=" * 80 + "\n\n")
        f.write(f"Total: {len(small_files)} archivos\n\n")
        
        for filepath in sorted(small_files):
            size_kb = get_file_size_kb(filepath)
            lines = count_code_lines(filepath)
            f.write(f"• {filepath:50} ({size_kb:6.1f}KB, {lines:3d} líneas)\n")
    
    # 2. ARCHIVOS IMPORTANTES
    with open("analisis_proyecto/archivos_importantes.txt", "w", encoding="utf-8") as f:
        f.write("=" * 80 + "\n")
        f.write("ARCHIVOS IMPORTANTES (> 5KB o > 100 líneas de código)\n")
        f.write("=" * 80 + "\n\n")
        f.write(f"Total: {len(important_files)} archivos\n\n")
        
        for filepath in sorted(important_files):
            size_kb = get_file_size_kb(filepath)
            lines = count_code_lines(filepath)
            f.write(f"• {filepath:50} ({size_kb:6.1f}KB, {lines:3d} líneas)\n")
    
    # 3. DOCUMENTACIÓN
    with open("analisis_proyecto/documentacion.txt", "w", encoding="utf-8") as f:
        f.write("=" * 80 + "\n")
        f.write("DOCUMENTACIÓN DEL ANÁLISIS\n")
        f.write("=" * 80 + "\n\n")
        
        f.write("📊 RESUMEN\n")
        f.write("-" * 80 + "\n")
        f.write(f"Total de archivos analizados: {len(important_files) + len(small_files)}\n")
        f.write(f"  • Archivos IMPORTANTES: {len(important_files)}\n")
        f.write(f"  • Archivos PEQUEÑOS: {len(small_files)}\n\n")
        
        f.write("🎯 CRITERIOS DE CLASIFICACIÓN\n")
        f.write("-" * 80 + "\n")
        f.write("Archivo IMPORTANTE si:\n")
        f.write("  • Tamaño > 5 KB\n")
        f.write("  • O más de 100 líneas de código\n\n")
        f.write("Archivo PEQUEÑO si:\n")
        f.write("  • Tamaño < 5 KB\n")
        f.write("  • Y menos de 100 líneas de código\n\n")
        
        f.write("📂 ESTRUCTURA\n")
        f.write("-" * 80 + "\n")
        f.write("analisis_proyecto/\n")
        f.write("├── archivos_importantes.txt   (Nombres de archivos críticos)\n")
        f.write("├── archivos_pequenos.txt      (Nombres de archivos auxiliares)\n")
        f.write("└── documentacion.txt          (Este archivo)\n\n")
        
        f.write("🔍 PRÓXIMOS PASOS\n")
        f.write("-" * 80 + "\n")
        f.write("1. Revisar 'archivos_importantes.txt' para código crítico\n")
        f.write("2. Revisar 'archivos_pequenos.txt' para código auxiliar\n")
        f.write("3. Usar esta información para optimizar o documentar el proyecto\n")

    print("✅ ANÁLISIS COMPLETADO\n")
    print(f"📁 Carpeta creada: analisis_proyecto/\n")
    print(f"📋 Archivos generados:")
    print(f"   • archivos_importantes.txt  ({len(important_files)} archivos)")
    print(f"   • archivos_pequenos.txt     ({len(small_files)} archivos)")
    print(f"   • documentacion.txt         (Guía de análisis)")
    print(f"\n📊 TOTALES: {len(important_files) + len(small_files)} archivos")

if __name__ == "__main__":
    analyze_project()
