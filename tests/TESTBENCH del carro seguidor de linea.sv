`timescale 1ns/1ps //Definición de la unidad de tiempo (1ns) y precisión de la simulación (1ps)

module carro_seguidor_tb;

  //=======================================================
  //ENTRADAS DEL DUT (Device Under Test) - Declaradas como reg
  //=======================================================
  reg CLK; //Señal de reloj del sistema
  reg S1;  //Estímulo para Sensor Izquierdo (0 = detecta línea, 1 = NO detecta)
  reg S2;  //Estímulo para Sensor Central   (0 = detecta línea, 1 = NO detecta)
  reg S3;  //Estímulo para Sensor Derecho   (0 = detecta línea, 1 = NO detecta)
  reg LDR; //Estímulo para el sensor óptico de arranque (0 = detecta Flash)

  //=======================================================
  //SALIDAS DEL DUT - Declaradas como wire para observar los cambios
  //=======================================================
  wire IN1; //Estado del Motor Izquierdo Adelante (PWM)
  wire IN2; //Estado del Motor Izquierdo Reversa  (PWM)
  wire IN3; //Estado del Motor Derecho Adelante   (PWM)
  wire IN4; //Estado del Motor Derecho Reversa    (PWM)

  //=======================================================
  //INSTANCIA DEL MÓDULO A PROBAR (UUT - Unit Under Test)
  //=======================================================
  carro_seguidor uut (
       .CLK(CLK),
       .S1(S1),
       .S2(S2),
       .S3(S3),
       .LDR(LDR),
       .IN1(IN1),
       .IN2(IN2),
       .IN3(IN3),
       .IN4(IN4)
  );

  //=======================================================
  //GENERADOR DE RELOJ 
  //Genera un flanco cada 5ns, logrando un Periodo = 10ns (100 MHz)
  //=======================================================
  always #5 CLK = ~CLK;

  //=======================================================
  //BLOQUE PRINCIPAL DE ESTÍMULOS DE PRUEBA
  //=======================================================
  initial begin
      //--- ESTADO INICIAL ---
      CLK = 0; //Inicializa el reloj en bajo
      LDR = 1; //El carro inicia en modo de espera (LDR en reposo, no ha detectado flash)
      S1  = 1; //Sensores inicialmente sobre la superficie clara / fuera de línea (Leen 1)
      S2  = 1;
      S3  = 1;

      #50; //Espera de estabilización inicial del sistema de 50 nanosegundos

      //--- ACTIVACIÓN MEDIANTE FLASH (LDR) ---
      LDR = 0; //Envía un pulso en bajo (Simula el destello del Flash sobre el fotorresistor)
      #20;     //Mantiene el pulso de luz por 20ns para asegurar la captura síncrona
      LDR = 1; //El flash termina. La bandera interna 'arrancar' ya debe fijarse en 1 de forma permanente.

      //--- CASO 1: AVANCE RECTO (3'b010) ---
      //Solo el sensor central (S2) detecta la línea negra (0). S1 y S3 permanecen en blanco (1).
      S1 = 1; S2 = 0; S3 = 1;
      #100; // Evalúa el comportamiento: Ambos motores deben avanzar hacia adelante (IN1 y IN3 con PWM)

      //--- CASO 2: GIRO CRÍTICO A LA IZQUIERDA (3'b100) ---
      //El carro se desvió a la derecha; S1 pierde el camino, S2 y S3 pisan la línea negra.
      S1 = 1; S2 = 0; S3 = 0;
      #100; //El motor derecho avanza con PWM (IN3) para corregir el rumbo, el izquierdo se apaga (IN1=0).

      //--- CASO 3: GIRO CRÍTICO A LA DERECHA (3'b001) ---
      //El carro se desvió a la izquierda; S3 pierde el camino, S1 y S2 pisan la línea negra.
      S1 = 0; S2 = 0; S3 = 1;
      #100; //El motor izquierdo avanza con PWM (IN1) para corregir el rumbo, el derecho se apaga (IN3=0).

      //--- CASO 4: CORRECCIÓN SUAVE A LA IZQUIERDA (3'b110) ---
      //El carro empieza a salirse por la derecha; únicamente el sensor derecho (S3) toca la línea negra.
      S1 = 1; S2 = 1; S3 = 0;
      #100; //El motor derecho avanza con PWM (IN3) e izquierdo apagado para reincorporarse al centro.

      //--- CASO 5: CORRECCIÓN SUAVE A LA DERECHA (3'b011) ---
      //El carro empieza a salirse por la izquierda; únicamente el sensor izquierdo (S1) toca la línea negra.
      S1 = 0; S2 = 1; S3 = 1;
      #100; //El motor izquierdo avanza con PWM (IN1) e derecho apagado para reincorporarse al centro.

      //--- CASO 6: REVERSA POR ENCRUCIJADA O PISTA PERDIDA (3'b000) ---
      //Los 3 sensores detectan negro simultáneamente (intersección completa o anomalía).
      S1 = 0; S2 = 0; S3 = 0;
      #100; //Ambos motores invierten su giro a velocidad controlada (IN2 y IN4 con PWM).

      //--- CASO 7: ESTADO ANÓMALO / CLÁUSULA DEFAULT (3'b101) ---
      //El sensor central lee blanco (1) y los laterales negro (0). Imposible en condiciones normales.
      S1 = 0; S2 = 1; S3 = 0;
      #100; //Entra a la zona de seguridad 'default': Ambos motores se desenergizan por completo (0).

      //--- CASO 8: PISTA PERDIDA POR COMPLETO / FUERA DE LÍNEA (3'b111) ---
      //Todos los sensores leen la superficie clara (1). El carro perdió la pista.
      S1 = 1; S2 = 1; S3 = 1;
      #100; //Entra a la zona 'default': Los motores permanecen apagados para evitar que el carro escape.

      //--- NOTA PARA DIGITALJS ---
      // Se comenta el $finish para evitar que el simulador interactivo web se interrumpa abruptamente.
      // $finish; 
  end

endmodule