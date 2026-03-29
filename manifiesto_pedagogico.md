# Manifiesto Pedagógico: Sinergia entre IA y Motor Gráfico

## La Regla de Oro: "Nunca asumir que el usuario entiende"
Tanto la Inteligencia Artificial (IA) como el motor gráfico de la aplicación operan bajo el principio fundamental de que **no se debe dar por sentado el conocimiento previo del usuario**. La aplicación no asume nada y, por lo tanto, debe estar preparada para explicar desde los conceptos más básicos hasta los más complejos, siempre respaldados por una representación visual clara.

No basta con enseñar a resolver un ejercicio de memoria; el objetivo es que el usuario comprenda el **porqué** matemático de cada acción.

---

## 1. Explicar el "Por Qué" (Fundamentos Visuales y Matemáticos)
Las reglas matemáticas no son magia ni convenciones arbitrarias. La aplicación debe encargarse de desmitificar estas reglas.

*   **Evitar axiomas ciegos:** La IA no debe limitarse a dictar instrucciones mecánicas (ej. "Para despejar $x$, pasa el $+5$ al otro lado restando"). 
*   **Representación del concepto:** Se debe responder siempre a la pregunta *¿Por qué hacemos esto?*. 
    *   *Ejemplo de Ecuaciones:* Si necesitamos despejar $x$, la IA y el motor gráfico deben mostrar que la ecuación funciona como una **balanza**. Para eliminar un $+5$ de un lado, agregamos un $-5$. Para que la balanza no pierda su equilibrio (el signo $=$), *estamos obligados* a agregar un $-5$ también en el otro lado.
*   **Visualización de la regla:** Esto se debe reflejar en la pantalla. El usuario debe ver literalmente cómo el motor gráfico aplica el cambio a ambos lados de la igualdad para mantener el balance, en lugar de simplemente ver un número "volar y cambiar de signo" mágicamente.

---

## 2. Responsabilidades del Motor Gráfico (El "Ver")
El motor gráfico es una herramienta pedagógica activa. Su trabajo es hacer tangible el pensamiento abstracto.

*   **Cero Teletransportación:** Los números, variables o elementos nunca desaparecen de un lado para aparecer en otro. Todo movimiento debe ser animado y trazar su recorrido físico. El ojo del usuario debe poder seguir de dónde vino la pieza y a dónde fue.
*   **Interactividad con Peso Físico:** Los elementos matemáticos deben sentirse manipulables y vivos. Deben tener animaciones sutiles (como un "wobble" al ser levantados), sombras que indiquen que están flotando, y resistencia visual si el usuario intenta hacer un movimiento matemáticamente inválido.
*   **Visibilidad de las Transiciones:** Cualquier transformación matemática (ej. simplificar una fracción, sumar términos semejantes) debe tener un efecto visual evidente que marque que ha ocurrido una mutación válida.

---

## 3. Responsabilidades de la IA (El "Guiar")
La IA actúa como un tutor observador, analítico y paciente; no como una simple calculadora que califica un resultado final.

*   **Monitoreo Inteligente y Eficiente (Control de Costos):** Para evitar un consumo excesivo de tokens en la API, la IA **no evalúa cada micro-interacción en tiempo real**. En su lugar, existe un trabajo en equipo:
    *   **El Motor Gráfico (Tracking Local):** Es el responsable de medir variables locales como el tiempo de inactividad, registrar movimientos inválidos consecutivos o contabilizar intentos frustrados. 
    *   **Activación Estratégica de la IA:** La IA solo entra en acción cuando recibe un "paquete de contexto" agrupado desde el motor gráfico (por ejemplo, después de 3 errores seguidos) o cuando el usuario solicita ayuda explícitamente. Al activarse, la IA usa este historial acumulado para dar una respuesta contextualizada sin haber gastado tokens en los pasos intermedios irrelevantes.
*   **Explicaciones Ancladas a lo Visual:** Toda explicación de la IA debe hacer referencia directa a lo que está ocurriendo o acaba de ocurrir en la pantalla. (Ej: *"¿Viste que la balanza se inclinó cuando quitaste el bloque? Necesitamos hacer lo mismo del otro lado"*).
*   **Mayéutica (Preguntas Socráticas):** Antes de dar la respuesta directa ante un atasco, la IA debe hacer preguntas que induzcan a la deducción del alumno. (Ej: *"Si queremos dejar la letra 'x' completamente sola, ¿qué bloque nos está molestando en ese lado?"*).

---

## 4. Framework Creador: Checklist para Futuros Ejercicios
Para asegurar que este principio de no asumir conocimiento se repita de forma sistemática en futuros módulos (fracciones, geometría, derivadas, etc.), se deberá seguir esta lista de verificación durante la etapa de diseño de cada nuevo tema:

1.  **Metáfora Visual:** ¿Cuál es la representación física o visual perfecta para este tema abstracto? (Ej: balanzas para ecuaciones, bloques divisibles para fracciones, *o la pendiente de una montaña rusa deslizable para la derivada de una función*).
2.  **El "Por Qué" Central:** ¿Cuál es la regla matemática principal de este tema y cómo la vamos a demostrar visualmente para que no parezca magia?
3.  **Desglose de Micro-pasos (Diseño de Interacciones):** Aquí es donde entra el trabajo de diseño duro. ¿Cuáles son los pasos atómicos necesarios para resolverlo visualmente en la pantalla? **Para cada nuevo tema (desde sumar fracciones hasta integrar polinomios), se deben diseñar específicamente las interacciones permitidas.** ¿El usuario debe "cortar" un bloque? ¿Debe deslizar un punto en una curva? El motor gráfico necesita reglas estrictas de qué se puede tocar y cómo reacciona.
4.  **Predicción de Errores Comunes:** ¿Qué confusiones conceptuales suelen tener los alumnos en este tema y cómo las va a identificar la IA al observar sus movimientos en el motor gráfico?
