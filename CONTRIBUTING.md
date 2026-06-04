# CONTRIBUTING

# Guía de Contribución - Carrito Seguidor de Línea (FPGA)

Este documento establece los estándares de trabajo para el desarrollo del carrito seguidor de línea en Verilog. El objetivo es mantener un repositorio organizado, profesional y funcional para la Experiencia Educativa de **Sistemas Digitales**.

## 1. FLUJO DE TRABAJO EN GIT (Orden del Repositorio)

Para evitar conflictos en la lógica RTL y asegurar que la versión en la FPGA siempre sea estable:

* **No toques `main`:** Nunca hagas commits directos a la rama principal. Es nuestra "versión de competencia".
* **Crea una rama por módulo:** Usa nombres que describan qué parte del hardware estás interviniendo:
    * `feat/control-pwm`: Cambios en la velocidad o divisor de frecuencia.
    * `feat/logica-sensores`: Implementación de los casos de los sensores IR.
    * `fix/sentido-giro`: Si los motores giran en sentido contrario al esperado.
    * `docs/evidencias`: Para subir fotos del chasis o esquemáticos.
* **Pull Request (PR):** Al terminar un módulo, sube tu rama y avisa al equipo. Al menos otro integrante debe verificar que el código sintetiza sin errores en **Gowin EDA** antes de unirlo a `main`.

## 2. ESTÁNDAR DE COMMITS (Historial legible)

Para entender qué cambió sin necesidad de leer todo el código Verilog:

* **feat:** Nueva funcionalidad de hardware (ej: *feat: implementado caso de reversa 000*).
* **fix:** Corrección de un error físico o lógico (ej: *fix: corregido pinout del sensor S3 en el .cst*).
* **test:** Cambios en los Testbenches de simulación.
* **docs:** Cambios exclusivos en el README, lista de componentes o comentarios.
* **style:** Limpieza de código o indentación que no afecta la síntesis.

## 3. ESTÁNDAR DE CÓDIGO (Verilog Limpio)

Al trabajar con hardware, la claridad evita comportamientos erráticos en los motores:

* **Nombres de señales explícitos:** No uses letras sueltas. Usa nombres que coincidan con el hardware: `pwm_pulso`, `motor_izq_A`, `sensor_centro`.
* **Asignaciones No Bloqueantes:** Para toda la lógica secuencial dentro de `always @(posedge CLK)`, utiliza siempre el operador `<=`.
* **Comentarios de Navegación:** Cada bloque de código debe explicar su función:
    * **Divisor de frecuencia:** Explicar a qué frecuencia queda el PWM.
    * **Casos de Sensores:** Indicar físicamente qué movimiento hace el carro (ej: *// Caso 001: Giro a la derecha*).
* **Seguridad y Latches:** El bloque `default` en el `case` debe apagar todos los motores por seguridad ante cualquier lectura inesperada.

## 4. VALIDACIÓN ANTES DE SUBIR CAMBIOS

Antes de realizar el merge a la rama principal, es obligatorio:

1.  **Sintetizar:** Verificar que el código compila al 100% en **Gowin V1.9.11**.
2.  **Verificar Restricciones (.cst):** Asegurarse de que los puertos del módulo `carro_seguidor` coincidan con los pines físicos asignados en la Tang Nano 9K.
3.  **Prueba del LDR:** Confirmar que la bandera `arrancar` bloquea correctamente los motores hasta recibir la señal del flash.

---
**¡A darle, equipo! Que este carrito sea el más rápido de TODOS.**
