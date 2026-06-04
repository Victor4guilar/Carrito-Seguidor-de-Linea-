module carro_seguidor(
    input CLK,        //Señal de reloj interna de la FPGA
    input S1,         //Sensor Izquierdo (0 = detecta línea, 1 = NO detecta)
    input S2,         //Sensor Central   (0 = detecta línea, 1 = NO detecta)
    input S3,         //Sensor Derecho   (0 = detecta línea, 1 = NO detecta)
    input LDR,        //Sensor de inicio (0 = detecta Flash)
 
    output reg IN1,   //Motor Izquierdo A
    output reg IN2,   //Motor Izquierdo B
    output reg IN3,   //Motor Derecho A
    output reg IN4    //Motor Derecho B
);
//Bandera de control para habilitar el movimiento general del circuito
reg arrancar = 0;
 
//Registro del Flash para el arranque seguro
always @(posedge CLK) begin
    if (LDR == 0)      //Si el LDR recibe luz del flash, se activa permanentemente
        arrancar <= 1;
end

//=======================================================
//GENERADOR DE PWM CON DIVISOR DE FRECUENCIA
//=======================================================
//Divisor para ralentizar el reloj original y que el Puente H responda
reg [3:0] divisor_frecuencia = 0; 
always @(posedge CLK) begin
    divisor_frecuencia <= divisor_frecuencia + 4'd1; //Contador síncrono de 4 bits
end

//El contador de PWM avanza al ritmo del bit más alto del divisor
reg [7:0] contador_pwm = 0;
always @(posedge divisor_frecuencia[3]) begin 
    contador_pwm <= contador_pwm + 8'd1;    //Escalado de reloj para bajar la frecuencia del PWM
end

//Ajuste de la velocidad del carro (153 es el 60% de la potencia del carro. El máximo es 255)
wire [7:0] velocidad = 8'd153;
//Generación del ciclo de trabajo (Duty Cycle) mediante comparación binaria 
wire pulso_pwm = (contador_pwm < velocidad) ? 1'b1 : 1'b0;

//=======================================================
//LÓGICA DE CONTROL DE LOS MOTORES (CASOS DE SENSORES)
//=======================================================
//Agrupamos los sensores: [S1, S2, S3]
wire [2:0] sensores = {S1, S2, S3};
 
always @(*) begin
    //Valores por defecto (Motores apagados)
    IN1 = 0; IN2 = 0;
    IN3 = 0; IN4 = 0;
 
    if(arrancar) begin  //El carro solo opera si la bandera de inicio fue activada por el LDR
        case (sensores)
            
            //=======================================================
            //CASO: Izquierdo y Derecho SÍ, Central NO (010)
            //Ambos motores avanzan al mismo tiempo
            //=======================================================
            3'b010: begin 
                IN1 = pulso_pwm; IN2 = 0; //Motor Izquierdo Adelante
                IN3 = pulso_pwm; IN4 = 0; //Motor Derecho Adelante
            end
            
            //=======================================================
            //CASO: Izquierdo NO detecta, central y derecho SÍ (100)
            //Giro a la Izquierda (Arranca Derecho, apaga izquierdo)
            //=======================================================
            3'b100: begin 
                IN1 = 0; IN2 = 0;         //Motor Izquierdo Apagado
                IN3 = pulso_pwm; IN4 = 0; //Motor Derecho Adelante
            end

            //=======================================================
            //CASO: Derecho NO detecta, central e izquierdo SÍ (001)
            //Giro a la Derecha (Arranca Izquierdo, apaga derecho)
            //=======================================================
            3'b001: begin 
                IN1 = pulso_pwm; IN2 = 0; //Motor Izquierdo Adelante
                IN3 = 0; IN4 = 0;         //Motor Derecho Apagado
            end
 
            //=======================================================
            //CASO MODIFICADO: Únicamente el derecho detecta algo (110)
            //El motor derecho avanza y el izquierdo NO
            //=======================================================
            3'b110: begin 
                IN1 = 0; IN2 = 0;         //Motor Izquierdo Apagado
                IN3 = pulso_pwm; IN4 = 0; //Motor Derecho Adelante
            end
 
            //=======================================================
            //CASO MODIFICADO: Únicamente el izquierdo detecta algo (011)
            //El motor izquierdo avanza y el derecho NO
            //=======================================================
            3'b011: begin 
                IN1 = pulso_pwm; IN2 = 0; //Motor Izquierdo Adelante
                IN3 = 0; IN4 = 0;         //Motor Derecho Apagado
            end
 
            //=======================================================
            //CASO: ÚNICAMENTE los 3 sensores detectan (000)
            //Ambos motores en REVERSA al mismo tiempo
            //=======================================================
            3'b000: begin 
                IN1 = 0; IN2 = pulso_pwm; //Motor Izquierdo Reversa
                IN3 = 0; IN4 = pulso_pwm; //Motor Derecho Reversa
            end
 
            //=======================================================
            //CASO POR DEFECTO: Apaga motores por seguridad ante 
            //Cualquier combinación no programada (evita latches).
            //=======================================================
            default: begin
                IN1 = 0; IN2 = 0;
                IN3 = 0; IN4 = 0;
            end
        endcase
    end
end
endmodule