# Tipos de Ejercicios a Implementar (Fase 1: Álgebra Fundamental)

Basado en nuestro "Framework Agnóstico", la clave está en elegir tipos de ejercicios que compartan las mismas **primitivas físicas** (Arrastrar, Colisionar, Equilibrar). Si elegimos bien, con un solo motor gráfico podremos resolver cientos de variantes de problemas.

Para no sobresaturar el desarrollo inicial, la **Fase 1** se enfocará en el "Álgebra Fundamental". Estos ejercicios son la base matemática de secundaria y preparatoria, y todos pueden resolverse usando la metáfora de la **Balanza** y los **Bloques Matemáticos**.

---

## 1. Ecuaciones Lineales Básicas (El Prototipo Actual)
*   **Ejemplo:** `2x + 5 = 15`
*   **Primitivas Necesarias:**
    *   `Drag & Drop + Balancing`: Arrastrar el `+5` cruzando el `=`, invirtiendo su signo a `-5`.
    *   `Merge (Aritmético)`: Chocar el `15` con el `-5` para que se fusionen en `10`.
    *   `Slice (División)`: Arrastrar el coeficiente `2` (que multiplica a la `x`), cruzar el `=` y soltarlo debajo del `10` como un divisor ($\frac{10}{2}$).
*   **Por qué es crucial:** Es el "Hola Mundo" de nuestra app. Si logras que esto se sienta bien físicamente, el 80% del motor estará listo.

## 2. Reducción de Términos Semejantes (Agrupación)
*   **Ejemplo:** `3x + 2 + 4x - 5 = 11`
*   **Primitivas Necesarias:**
    *   `Drag & Merge (Algebraico)`: El motor debe permitir agarrar el `+4x` y arrastrarlo sobre el `3x`. Al soltarlo, se fusionan físicamente en un bloque `7x`.
    *   `Repulsión`: Si el usuario intenta chocar el `+2` con el `3x`, los bloques rebotan magnéticamente indicando que son "especies distintas".
*   **Por qué es crucial:** Introduce la regla de que no todo se puede sumar con todo. La UI le enseña implícitamente qué cosas son "combinables".

## 3. Resolución con Múltiples Variables en Ambos Lados
*   **Ejemplo:** `5x - 3 = 2x + 9`
*   **Primitivas Necesarias:**
    *   Todas las anteriores. No requiere mecánicas nuevas, solo aplica las existentes a un problema más largo. Introduce la necesidad pedagógica de "agrupar variables de un lado y números del otro".

## 4. Ecuaciones con Fracciones Simples (Proporciones)
*   **Ejemplo:** $\frac{x}{3} + 2 = 6$
*   **Primitivas Necesarias:**
    *   `Drag & Drop (Multiplicación cruzada)`: Agarrar el divisor `3`, cruzar la línea del `=` hacia la derecha, y soltarlo para que multiplique al lado derecho completo `(6 - 2) * 3`.
    *   `Animación de Transición (Construcción/Desmontaje)`: Al crear una fracción (ej. arrastrar un `x` sobre un `/3`), los números no aparecen "de golpe" uno sobre otro. **La línea divisoria debe crecer horizontalmente** desde el centro mientras el numerador sube suavemente y el denominador baja, acomodándose en su nueva posición física. A la inversa, al pasar el `3` multiplicando, la línea debe encogerse y desaparecer mientras la `x` vuelve a caer a su nivel base.
*   **Por qué es crucial:** Introduce el eje vertical (división/multiplicación) al movimiento físico y requiere animaciones de interpolación vertical (estiramiento y alineación) para que el cerebro acepte la nueva estructura matemática.

---
## VISTA A FUTURO: Escalabilidad Infinita (Fases 2+)

El diseño de estas 4 primitivas base está pensado para que **no tengas que reprogramar el motor** cuando pases a temas más complejos. Solo añadirás nuevas reglas de "fusión" (Merge) y "desglose" (Slice) al AST.

Aquí tienes cómo este mismo núcleo soportará infinitos casos avanzados:

*   **Propiedad Distributiva:** `3(x + 2) = 15`. 
    *   *Mecánica:* Tocar el `3` y hacer un gesto de deslizar hacia adentro del paréntesis. El motor gráfico clona el `3` y lo hace chocar (Merge) contra la `x` y contra el `2`. 
*   **Factorización (Factor Común):** `2x + 6 = 10`.
    *   *Mecánica:* El inverso a la distributiva. Gesto de "pellizcar" o agrupar el `2x` y el `6`. El motor extrae físicamente el `2` hacia afuera, dejando `2(x + 3)`.
*   **Ecuaciones Cuadráticas / Cúbicas:** `x^2 - 4 = 0`.
    *   *Mecánica:* Pasar el `-4` a `+4`. Luego, aislar `x` agarrando el exponente `^2`, cruzar el `=`, y que el motor lo dibuje transformándose en un bloque de $\pm\sqrt{\quad}$ encadenando al `4`.
*   **Propiedades de la Potencia:** `x^3 * x^2 = 32`.
    *   *Mecánica (Merge Exponencial):* Chocar los bloques `x` enteros. Si las bases coinciden, el motor repela las bases pero fusiona (suma) "visualmente" los bloques de exponentes pequeños `3 + 2` transformándose en `x^5`.
*   **Fracciones Algebraicas (Racionales):** $\frac{x^2 - 1}{x - 1} = 5$.
    *   *Mecánica:* Cortar el numerador usando un gesto (Slice) en `(x+1)(x-1)`. Luego, "tachar" físicamente (Merge destructivo) los bloques `(x-1)` de arriba y abajo.

---

## El Mapa de Ruta Estratégico

Si te fijas, **no necesitamos programar 4 juegos distintos**. Solo necesitamos un motor que sepa hacer 4 cosas:
1.  Cruzar el `=` invierte la operación (Suma $\leftrightarrow$ Resta, Mult $\leftrightarrow$ Div).
2.  Número choca con Número $\rightarrow$ se suman/restan.
3.  `x` choca con `x` $\rightarrow$ se suman/restan sus coeficientes.
4.  Número choca con `x` $\rightarrow$ Rebotan.

Con ese núcleo programado, la API (tu backend en Python) puede mandarte un JSON con un problema del Tipo 1, Tipo 2, Tipo 3 o Tipo 4, y tu aplicación en Flutter sabrá cómo renderizarlo y jugarlo sin esfuerzo adicional.

¿Te parece bien arrancar la primera etapa definiendo estos 4 tipos de ejercicios en nuestro editor JSON? Así nos aseguramos de que el AST (Árbol Matemático) sea capaz de soportar la complejidad de la "fracción simple" antes de escribir código visual.
