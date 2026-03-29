# Framework de Diseño Agnostic: Un Flujo Único y Universal

Este documento extiende los principios del `manifiesto_pedagogico.md` y establece un marco de trabajo estandarizado para diseñar **cualquier** interacción matemática en la aplicación.

**Regla de Oro Adicional: El sistema es ciego al "Nivel Educativo".**
La aplicación no sabe si el usuario está en primaria, secundaria o la universidad, **ni le importa**. Categorizar las interacciones por "nivel" viola el principio de no asumir. Un estudiante universitario puede necesitar ayuda visual con una suma de fracciones, y un niño podría estar explorando geometría espacial. Por lo tanto, el diseño se basa en un **único flujo universal de primitivas físicas**, aplicables a cualquier concepto.

---

## 1. El Vocabulario Físico Universal (Interacciones Primitivas)

En lugar de crear un motor distinto para cada tema matemático, construimos un "universo físico base". Todo concepto matemático, sin importar su complejidad abstracta, debe traducirse a combinaciones de estas interacciones primitivas:

*   **Arrastrar y Colisionar (Drag, Drop & Merge):**
    *   *Aplicación Numérica:* Mover un bloque `3` sobre un `5` para que se fusionen en `8`.
    *   *Aplicación Operacional:* Arrastrar un operador como $\frac{d}{dx}$ (derivada) sobre una función $f(x)$ para interaccionar con ella.
*   **Separar / Desagrupar (Desmontaje Fluido):**
    *   *Aplicación Numérica:* Partir un bloque no es un corte seco tipo tijera. Al intentar separar un `1` en fracciones, debe mostrarse una animación de estiramiento donde el `1` se desdobla o deconstruye suavemente revelando $\frac{1}{2}$ y $\frac{1}{2}$ como sub-piezas físicas.
    *   *Aplicación Operacional:* Separar una integral de una suma en dos integrales independientes.
*   **Equilibrar (Balancing):**
    *   El principio fundamental de las ecuaciones. Un eje central `=` que exige simetría de "peso" (operaciones) en ambos lados para no romperse.
*   **Deslizar Mando (Scrubbing / Slider):**
    *   Permite explorar el cambio continuo. Funciona igual para explorar números negativos en una recta numérica, como para explorar el cambio de la pendiente ($m$) en una gráfica lineal, o los límites de un área bajo la curva.

---

## 2. El Flujo Único de Diseño (El Pipeline)

Cualquier nuevo bloque matemático que quieras introducir en la aplicación debe pasar exactamente por este mismo flujo de diseño de 4 pasos, sin excepciones:

### PASO 1: Traducción a la Metáfora Visual
Convierte la abstracción matemática en un objeto físico y visual.
*   *¿Qué representa este concepto en el espacio?* (Ej: Una ecuación es una balanza. Una matriz es una grilla que deforma el espacio. Una derivada es la pendiente de una montaña rusa sobre la curva).

### PASO 2: Guion del "Aha! Moment"
Identifica cuál es el concepto central que el motor gráfico debe evidenciar. Si el motor gráfico solo hace este paso bien, el usuario debería entender el tema sin palabras.
*   *Ejemplo:* Ver cómo al sacar un número de un sube y baja (balanza), este se inclina violentamente, obligando a sacar el mismo número del otro lado.

### PASO 3: Definición del Árbol de Estados (Reglas de Física Matemática)
El motor gráfico solo maneja colisiones y restricciones físicas. Aquí defines las reglas de esa física:
1.  **Reglas de Fusión (Merge Rules):** ¿Qué ocurre cuando el Objeto A choca con el Objeto B? 
    *   *Ejemplo base:* Bloque $x$ choca con bloque $x \rightarrow$ se fusionan en $2x$.
    *   **Proporción Visual Dinámica (Feedback de Fusión):** Al chocar dos bloques numéricos o términos, el tamaño físico del bloque resultante reflejará la operación. Si la operación incrementa el valor absoluto (ej: `3` + `2`), el bloque se hincha visualmente. Si lo reduce (ej: `5` choca con `-3`), el bloque se encoge o se consume, como si el negativo le "arrancara" masa al positivo, resultando en un pequeño `2`.
2.  **Transiciones Animadas Universales (El Estándar Anti-Teletransportación):** **En este motor gráfico, NINGÚN cambio ni operación ocurre en seco.** Todo salto lógico se modela con una transición de entre 300ms a 500ms. 
    *   *Suma/Resta:* Los bloques no desaparecen, colisionan y se funden ("morfosean") en su resultado.
    *   *Cambio de Signo:* Al arrastrar algo sobre el `=`, el bloque debe voltearse, vibrar o dar un destello para indicar la permutación de su carga (de positivo a negativo o viceversa).
    *   *Multiplicación/Factorización:* Si se aplica distributiva $3(x+2)$, el `3` no se duplica de la nada. Se ve cómo el bloque original `3` estira un cordón o se divide como una célula en dos bloques de `3` que vuelan a impactar a la `x` y al `2`.
    *   *Cancelación:* Si se anulan dos bloques opuestos (ej: $+5$ y $-5$, o la misma fracción en numerador y denominador), no se borran mágicamente; deben encogerse, disolverse en partículas o soltar una nube de humo gráfico que indique su evaporación del espacio matemático.
    *   **Propósito:** El cerebro humano usa las animaciones para comprender el álgebra. La acción física *es* la explicación matemática.
3.  **Leyes de Restricción (Movimientos Ilegales):** ¿Qué paredes invisibles o rebotes existen? (Ej: No puedes sumar letras distintas, el motor hace que se repelan magnéticamente).

### PASO 4: Empaquetado de Contexto para la IA
Define qué telemetría enviará el Motor Gráfico a la IA cuando el usuario necesite rescate. Todo módulo debe enviar:
*   Estado inicial del problema.
*   Estado actual (qué bloques quedaron en la pantalla).
*   Historial de los últimos N movimientos fallidos o choques ilegales.
*   Tiempo transcurrido en inactividad.

---

## 3. Conclusión: Física, no Temarios

Al eliminar el concepto de "niveles", te liberas de diseñar para secundaria o preparatoria. **Tú te conviertes en el diseñador de las leyes de la física de un universo matemático.**

Si quieres meter un tema nuevo, simplemente piensas: *¿Qué primitivas físicas (arrastrar, cortar, balancear, deslizar) necesito combinar para que este sub-mundo abstracto tenga sentido táctil y visual?* Y la IA usará esa misma física para observar y guiar, sin juzgar la "edad" o el "nivel" del usuario.
