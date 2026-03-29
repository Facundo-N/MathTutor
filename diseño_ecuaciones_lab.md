# Aplicación del Framework de Diseño Agnostic: Laboratorio de Ecuaciones

Este documento aplica el "Framework de Diseño Agnostic" directamente a nuestro prototipo actual: el **Laboratorio de Ecuaciones**. Esto nos servirá como el primer caso de éxito de nuestra arquitectura física y universal, demostrando cómo una simple ecuación lineal alberga conceptos de sumas, restas y balanzas abstractas.

---

## FASE 1: Traducción a la Metáfora Visual

Una ecuación no es una cadena de texto a resolver; es un objeto tridimensional que existe en un espacio con reglas estrictas.

*   **Metáfora Principal:** La Ecuación como una **Balanza de Precisión**.
    *   El signo `=` es el eje central de rotación.
    *   Los lados izquierdo y derecho son platillos suspendidos.
    *   Cada número o variable (como `+5` o `3x`) es un **bloque físico con un peso**. Los bloques positivos jalan hacia abajo (añaden peso), los bloques negativos son como globos de helio (tiran hacia arriba).
*   **La Física del Motor:** Si el peso neto del lado izquierdo no es matemáticamente igual al lado derecho, el motor gráfico hace que la balanza se incline bruscamente hacia el lado más pesado.

## FASE 2: Guion del "Aha! Moment" (La Iluminación Visual)

¿Cuál es el concepto clave que queremos enseñar sin usar una sola palabra?
**Que cambiar de lado implica cambiar de signo u operación (Ley Uniforme).**

**Guion de Interacción "Aha!":**
1.  El usuario tiene `x + 3 = 8`. La balanza está en equilibrio.
2.  El usuario quiere dejar la `x` sola. Agarra el bloque `+3` y lo arrastra literalmente al otro lado (el platillo derecho) tal como está (`+3`).
3.  **El Sistema Reacciona:** Al soltar el `+3` en la derecha, ahora el lado derecho pesa muchísimo más (`8 + 3 = 11`) mientras la izquierda pesa poco (`x`). La balanza se ladea violentamente con un ruido de desequilibrio, la pantalla hace un ligero flash rojo, y la ecuación tiembla.
4.  **Corrección Visual:** El usuario deduce (o el motor le sugiere sutilmente con un glow) que al levantar un `+3` para cruzar la línea del `=`, el bloque debería "voltearse" e invertirse en un `-3`. Al ser negativo (globo), cancela peso en el número `8`, dejándolo en `5`. La balanza vuelve a la serenidad.
5.  *Aha! Moment logrado: Al cruzar el igual, debes hacer la operación contraria para mantener el universo en balance.*

## FASE 3: Definición del Árbol de Estados (Reglas de Física Matemática)

El motor gráfico de Flutter debe ser riguroso con los permisos de colisión (las mecánicas táctiles lícitas de nuestro universo numérico):

*   **Arrastrar y Soltar (Movimiento Universal):**
    *   Puedes agarrar cualquier bloque huérfano (ej: un `+3`).
    *   Si agarras un bloque atado a otro (ej. `2` en `2x`), estás intentando romper un producto. La física demanda que, al separarlo, cruce el `=` como un divisor.
*   **Colisionar (Merge Rule - Reducción de Términos):**
    *   *Colisión Válida:* Un bloque numérico choca con otro numérico (`+4` choca con `-1` $\rightarrow$ animación de compresión que escupe un `+3`).
    *   *Colisión Válida:* Bloques de la misma especie chocan (`2x` choca con `3x` $\rightarrow$ se fusionan en `5x`).
    *   *Colisión Inválida (Repulsión):* `5` intenta chocar con `2x`. El motor gráfico los repele como imanes de la misma polaridad con un zumbido táctil. "La física prohíbe fundir naranjas con manzanas".
*   **Desglosar (Slice - Factorización Temporal):**
    *   Fraccionar un `6` en dos bloques de `3` con un gesto de tijera si se necesita distribuir peso.

## FASE 4: Empaquetado de Contexto para la IA

Cuando el motor gráfico detecte frustración (el estudiante desequilibró la balanza 4 veces seguidas intentando pasar términos mal), empaqueta el evento y llama a la IA.

**Estructura Crítica del JSON enviado (Contexto para IA):**
```json
{
  "ejercicio_id": "ecuaciones_lvl_1",
  "estado_inicial": "2x + 5 = 11",
  "estado_actual": "2x = 11 + 5",
  "tiempo_transcurrido": "45s",
  "consecutivos_invalidos": 3,
  "ultimo_error": {
     "tipo": "desequilibrio_por_signo",
     "accion": "Movió bloque +5 al lado derecho sin cambiar su signo a negativo."
  }
}
```

**Respuesta de la IA (Basada en el manifiesto):**
*(Sabiendo el contexto exacto gracias al motor gráfico, la IA entra de forma Socrática y Visual):*
"¡Ojo ahí! 🕵️‍♀️ ¿Qué le pasó a la balanza cuando pasaste ese `+5` con su mismo signo? ¡Pesaba de más en la derecha! Recuerda la regla de oro: si cruzamos el puente del igual `$=$`, debemos invertirlo para mantener el orden. ¿Cómo quedaría si cruzara al revés, restando?"
