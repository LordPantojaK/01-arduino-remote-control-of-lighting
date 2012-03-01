/*
  ARDUINO MINI PRO - PAH: PROYECTO DE ALUMBRADO DE UNA HABITACIÓN, 27/1/2012, v1.1
 
  BLOG:   http://giltesa.com/tag/pah/
  Licendia: http://creativecommons.org/licenses/by-nc-sa/3.0/es

  El siguiente código permite controlar el alumbrado de una habitación por medio de un relé.
  Para ello dispone de diferentes modos de control y de diferentes modos de funcionamiento.
  Puede controlarse manualmente mediante pulsaciones o mediante un mando a distancia por infrarrojos.
  En ambos casos las funcionalidades son las mismas aunque varia la forma de acceder a ellas.
 
  CONTROL MANUAL MEDIANTE PULSACIONES:
 
  Una pulsación corta enciende o apaga la luz.
    Dos pulsaciones cortas y seguidas y separadas entre ellas por un máximo de 1 segundo programaran el apagado automático de la luz en 5 minutos. Solo funciona si la luz esta encendida.
      Una pulsación corta desactivara el apagado automático y apagara la luz.
 
  Una pulsación larga activa el modo programación, dentro del modo programación:
    Una pulsación corta aumenta en 5 minutos el tiempo de apagado, el tiempo podrá ser máximo de 1 hora.
    Una pulsación larga desactiva el modo programación y comienza el apagado automático con el tiempo programado.
      Una pulsación corta desactivara el apagado automático y apagara la luz.
 
  CONTROL MEDIANTE MANDO A DISTANCIA:
 
  Se controlan todas las funciones mediante tres botones, sea el mando que sea.
    El primer botón:  Enciende o apaga la luz, también desconecta un apagado programado y apaga la luz a continuación.
    El segundo botón: Activa el apagado automático de 5 minutos, o incrementa 5 minutos el tiempo dentro del modo programación.
    El tercer botón:  Entra y sale del modo programación.
 
  NOTA:
    Normalmente los mandos a distancia mandan dos códigos distintos, el primero es el correspondiente al botón pulsado, el segundo es uno genérico entre todos los botones y que ha de ser desechado, este código sigue enviándose hasta que se deja de pulsar el botón y esto nos permite programar el código de forma sencilla.
    SIN CONTROLAR POR COMPLETO -> Sin embargo no todos los mandos funcionan así y hay casos especiales, por ejemplo con el mando de Microsoft MCE, cada botón tiene dos códigos validos y distintos del resto, y cuando es pulsado el botón se envía uno de esos dos códigos de forma duplicada y repetida hasta que deja de ser pulsado, por ello hay que comprobar ambos códigos y hay que configurar el programa para que solo se lean los códigos separados entre si por un periodo de tiempo determinado.
*/
/*
  CHANGE LOG:
 
  v1.0 08/01/2012:
    Programa base.
 
  v1.1 27/01/2012:
     Modificado el tiempo minimo para la pulsacion corta, de 100 a 20ms.
     Añadido un aviso sonoro para advertir del apagado automático inminente.
*/
 
/* LIBRERÍAS, CONSTANTES y VARIABLES GLOBALES ********************************************/
 
  // LIBRERIAS
    #include <IRremote.h>
 
  // PINES ARDUINO MINI PRO
    #define ledVerde  2
    #define ledRojo   3
    #define rele    4
    #define fototrans 5
    #define buzzer    6
    #define pulsador  7
 
  // TIEMPO EN MILISEGUNDOS
    #define pulCortaMin   20    // Duración minima de una pulsación corta.
    #define pulCortaMax   1000  // Duración máxima de una pulsación corta.
    #define pulLarga    2000  // Duración minima de una pulsación larga.
    #define tiempoApagado 300000  // Mínimo tiempo de apagado, 5 minutos.
    #define velParpadeo   500   // Velocidad de parpadeo del led verde.
    #define tiempoAviso   60000 // Tiempo para el aviso del apagado inminente.
 
  // ESTADO DEL PROGRAMA
    boolean estadoLuz = false;
    boolean estadoLed = false;
    boolean estApagAuto = false;
    boolean estadoAviso = false;
 
  // CODIGOS DE LOS MANDOS
    // Los botones:
    #define onOff   0
    #define apagadoAuto 1
    #define modoProgra  2
 
    // Número de botones - Número de mandos:
    #define numBotones  3
    #define numMandos   4
    unsigned long losCodigos[numBotones][numMandos] =
    {
    //Mando:  Microsoft MCE      ,  Chino YK-001, Apple Remote
           { 2148500571, 2148467803,    16753245, 2011242676 }, // On Off
           { 2148500572, 2148467804,    16769565, 2011287732 }, // Apagado Automático
           { 2148500573, 2148467805,    16736925, 2011250868 }  // Modo Programación
    };
 
  // VARIABLE GLOBAL PARA LA FUNCION "compruebaCodigo"
    unsigned long tiempoUltimaLecturaIR = 0;
 
  // INICIALIZACIÓN DEL FOTOTRANSISTOR
    IRrecv irrecv(fototrans);
    decode_results results;
 
/******************************************** LIBRERÍAS, CONSTANTES y VARIABLES GLOBALES */
 
// CONFIGURACIÓN DEL HARDWARE
void setup()
{
  pinMode( ledVerde,  OUTPUT );
  pinMode( ledRojo, OUTPUT );
  pinMode( rele,    OUTPUT );
  pinMode( buzzer,  OUTPUT );
  pinMode( pulsador,  INPUT  );
 
  Serial.begin(9600);  // Depuracion
  irrecv.enableIRIn(); // Activación de la recepción de datos por infrarrojos
 
  digitalWrite( ledVerde, HIGH );
};
 
// FUNCIÓN QUE COMPRUEBA SI EL "codigoIR" PERTENECE A ALGUNO DE LOS BOTONES DE ALGUNO DE LOS MANDOS UTILIZABLES
boolean compruebaCodigo( int elBoton, unsigned long codigoIR, boolean forzarIR )
{
  /*
  Precondición:
          Es necesaria una matriz de enteros de tamaño "numBotones" x "numMandos" definida como global y que guarda todos los códigos correspondientes a cada botón.
          También la variable global "tiempoUltimaLecturaIR" en la que se guardara los milisegundos de la ejecución anterior de la función.
          La función ha de recibir un entero que indica el botón del cual se quieren comprobar sus códigos.
          El segundo parámetro es de tipo unsigned long con el codigoIR recibido.
          Y el tercer parámetro booleano que indica si se ha de ignorar el tiempo entre ejecuciones de la función.
  Poscondición:
          Se comprueba si el codigoIR coincide con alguno de los códigos del botón pulsado. Se devuelve true si coincide, false en caso contrario.
  */
 
  unsigned long tiempoAhora = millis();
  boolean respuesta = false;
  int i;
 
  // Solo ejecutar el código si ha pasado más de 1000 milisegundos desde la ultima ejecución o si se quiere forzar una nueva lectura IR:
  if( tiempoAhora - tiempoUltimaLecturaIR > 1000  ||  !forzarIR )
  {
    for( i=0; i < numMandos; i++ )
      if( losCodigos[elBoton][i] == codigoIR )
        respuesta = true;
 
    tiempoUltimaLecturaIR = tiempoAhora; // Se actualiza el tiempo de la ultima ejecución.
  };
 
  return respuesta;
};
 
// FUNCIÓN QUE APAGA LA LUZ EN EL TIEMPO PROGRAMADO
void apagadoProgramado( int multiplicador )
{
  /*
  Precondición:
          Se ha de recibir un parámetro de tipo entero en el rango de 1~12
  Poscondición:
          Se permanecerá dentro de esta función hasta que pase el tiempo programado o se pulse el botón de la pared o del mando a distancia.
  */
 
  unsigned long tiempoAhora = millis();
  unsigned long tiempoPrevio = tiempoAhora;
  unsigned long tiempoPrevioDos;
  unsigned long tiempoParpadeoPrevio = tiempoAhora;
  unsigned long tiempoTranscurrido;
  unsigned long codigoIR;
 
  // Pitido de aviso del apagado automatico:
  digitalWrite( buzzer, HIGH ); delay(10);
  digitalWrite( buzzer, LOW  ); delay(100);
  digitalWrite( buzzer, HIGH ); delay(10);
  digitalWrite( buzzer, LOW  ); delay(100);
  digitalWrite( buzzer, HIGH ); delay(10);
  digitalWrite( buzzer, LOW  );
 
  Serial.print("Apagado programado en "); Serial.print( ((multiplicador*tiempoApagado)/1000)/60 ); Serial.println(" minutos"); // Depuracion
 
  // Mientras el tiempo de ahora sea inferior al tiempo previo + ( el número de pulsaciones * el tiempo de apagado ):
  while( tiempoAhora < tiempoPrevio+(multiplicador*tiempoApagado)  &&  estadoLuz )
  {
 
    tiempoAhora = millis();
    tiempoPrevioDos = tiempoAhora;
    tiempoTranscurrido = 0;
 
    // Durante el apagado automático se hace parpadear el led cada medio segundo:
    if( tiempoAhora - tiempoParpadeoPrevio >= velParpadeo )
    {
      if( !estadoLed )
      {
        digitalWrite( ledVerde, HIGH );
        estadoLed = true;
      }
      else
      {
        digitalWrite( ledVerde, LOW );
        estadoLed = false;
      };
 
      tiempoParpadeoPrevio = tiempoAhora;
    };
 
    // En caso de que se pulse el botón, se mide la duración:
    while( digitalRead(pulsador) == HIGH )
    {
      tiempoAhora = millis();
      tiempoTranscurrido = tiempoAhora - tiempoPrevioDos;
    };
 
    // Si se recibe una señal infrarroja se guarda en "codigoIR"
    if( irrecv.decode(&results) )
    {
      irrecv.resume();        // Se recibe el próximo valor
      codigoIR = results.value;   // Se guarda el valor recogido
      //Serial.print("Codigo IR: "); Serial.println(codigoIR); // Depuracion
    };
 
    // Si se pulsa el botón, o el botón del mando a distancia se interrumpe el apagado automático y se apaga la luz:
    if( tiempoTranscurrido > pulCortaMin  &&  tiempoTranscurrido < pulCortaMax  ||  compruebaCodigo(onOff, codigoIR, false) )
    {
      digitalWrite( rele, LOW );
      digitalWrite( ledVerde, HIGH );
      estadoLuz = false;
      estadoAviso = false;
      Serial.println("Apagado automatico cancelado, luz apagada"); // Depuracion
    };
 
    // Cuando falten 1000 milisegundos para completar el tiempo de apagado, apagar la luz:
    if( tiempoAhora > tiempoPrevio+((multiplicador*tiempoApagado)-1000) )
    {
      digitalWrite( rele, LOW );
      digitalWrite( ledVerde, HIGH );
      estadoLuz = false;
      estadoAviso = false;
      Serial.println("Apagado automatico realizado, luz apagada"); // Depuracion
    };
 
    // Cuando falten 60.000 milisegundos para completar el tiempo de apagado, avisar con un pitido:
    if( !estadoAviso  &&  estadoLuz  &&  tiempoAhora > tiempoPrevio+((multiplicador*tiempoApagado)-tiempoAviso) )
    {
      estadoAviso = true;
      digitalWrite( buzzer, HIGH ); delay(5);
      digitalWrite( buzzer, LOW  ); delay(250);
      digitalWrite( buzzer, HIGH ); delay(5);
      digitalWrite( buzzer, LOW  );
      Serial.println("Se aproxima el apagado automatico de la luz"); // Depuracion
    };
 
  };
 
};
 
// FUNCIÓN PRINCIPAL (BUCLE)
void loop()
{
 
  unsigned long tiempoPrevio = millis();  // Se guarda el tiempo que lleva encendido el sistema.
  unsigned long tiempoAhora;
  unsigned long tiempoTranscurrido = 0;
  unsigned long multiplicador = 0;
  unsigned long codigoIR;
 
  /* MODO DE CONTROL MANUAL ***************************************************************/
 
    // Durante la pulsación del botón se calcula el tiempo de diferencia del sistema desde que se entro en la iteración hasta que se salio:
    while( digitalRead(pulsador) == HIGH )
    {
      tiempoAhora = millis();
      tiempoTranscurrido = tiempoAhora - tiempoPrevio;
 
      // Si la pulsación excede de 3000 milisegundos y la luz esta encendida, se enciende el led rojo para avisar de que se ha accedido al modo programación:
      if( tiempoTranscurrido >= pulLarga  &&  estadoLuz )
        digitalWrite( ledRojo, HIGH );
    };
    //if( tiempoTranscurrido != 0 ) Serial.println(tiempoTranscurrido); // Depuracion
 
    // Si el tiempo que se ha calculado corresponde al de una pulsación corta:
    if( tiempoTranscurrido > pulCortaMin  &&  tiempoTranscurrido < pulCortaMax )
    {
 
      tiempoPrevio = tiempoAhora;
 
      // Si la luz esta apagada, simplemente se enciende:
      if( !estadoLuz )
      {
        digitalWrite( rele, HIGH );
        digitalWrite( ledVerde, LOW );
        estadoLuz = true;
        Serial.println("Luz encendida"); // Depuracion
      }
      else // En cambio, si la luz ya estaba encendida...
      {
 
        // Durante los próximos 1000 milisegundos puede darse el caso de que haya otra pulsación:
        while( tiempoAhora < tiempoPrevio+1000 )
        {
          tiempoAhora = millis();
 
          // En caso de haber otra pulsación, se calcula su tiempo de duración:
          if( digitalRead(pulsador) == HIGH )
          {
            // Guardar la duración de la pulsación:
            while( digitalRead(pulsador) == HIGH )
            {
              tiempoAhora = millis();
              tiempoTranscurrido = tiempoAhora - tiempoPrevio;
            };
 
            // Si la pulsación vuelve a corresponder con una pulsación corta se obtiene una doble pulsación y activa el apagado automático:
            if( tiempoTranscurrido > pulCortaMin  &&  tiempoTranscurrido < pulCortaMax )
              estApagAuto = true;
 
          };
 
        };
 
        // En caso de no haberse activado el apagado automático, se apaga la luz:
        if( !estApagAuto )
        {
          digitalWrite( rele, LOW );
          digitalWrite( ledVerde, HIGH );
          estadoLuz = false;
          Serial.println("Luz apagada"); // Depuracion
        }
          // En caso contrario programar el apagado en 5 minutos:
        else
        {
          apagadoProgramado(1);
          estApagAuto = false;
        };
      };
 
    }
      // Si en vez de una pulsación corta se hiciese una larga y con la luz encendida, se entra en el modo programación:
    else if( tiempoTranscurrido >= pulLarga  &&  estadoLuz )
    {
      Serial.println("Modo programacion activado"); // Depuracion
 
      // Hasta que la pulsación recogida no sea una pulsación larga no se saldrá del modo programación:
      do{
 
        tiempoPrevio = millis();
        tiempoTranscurrido = 0;
 
        // Cuando se pulse el boton:
        if( digitalRead(pulsador) == HIGH )
        {
          // Se calcula el tiempo de la pulsación:
          while( digitalRead(pulsador) == HIGH )
          {
            tiempoAhora = millis();
            tiempoTranscurrido = tiempoAhora - tiempoPrevio;
 
            // Cuando la pulsación exceda de 2000 milisegundos se apaga el led rojo para avisar que se sale del modo programación:
            if( tiempoTranscurrido >= pulLarga )
              digitalWrite( ledRojo, LOW );
          };
 
          // Si la duración corresponde a una pulsación corta, se contabiliza en el multiplicador:
          if( tiempoTranscurrido > pulCortaMin  &&  tiempoTranscurrido < pulCortaMax )
          {
            multiplicador++;
 
            // Y se emite un pitido de aviso:
            digitalWrite( buzzer, HIGH ); delay(10);
            digitalWrite( buzzer, LOW  );
          };
 
          // Si se llega al límite de tiempo, 60 minutos/12 pulsaciones, se avisa con un doble pitido:
          if( multiplicador == 13 )
          {
            multiplicador--;
            delay(20);
            digitalWrite( buzzer, HIGH ); delay(10);
            digitalWrite( buzzer, LOW  ); delay(15);
            digitalWrite( buzzer, HIGH ); delay(10);
            digitalWrite( buzzer, LOW  );
          };
 
        };
 
      } while( tiempoTranscurrido <= pulLarga );
 
      // Si el multiplicador no es 0, es decir, se ha pulsado mínimo el botón 1 vez:
      if( multiplicador != 0 )
        apagadoProgramado(multiplicador);
      else
        Serial.println("Modo programacion cancelado"); // Depuracion
 
    };
 
  /*************************************************************** MODO DE CONTROL MANUAL */
 
  /* MODO DE CONTROL POR MANDO A DISTANCIA ************************************************/
 
    // Si se recibe una señal infrarroja se guarda en "codigoIR"
    if( irrecv.decode(&results) )
    {
 
      irrecv.resume();        // Se recibe el próximo valor
      codigoIR = results.value;   // Se guarda el valor recogido
      //Serial.print("Codigo IR: "); Serial.println(codigoIR); // Depuracion
 
      // Si la luz esta apagada y la señal recibida corresponde con la del botón "onOff" se enciende la luz:
      if( !estadoLuz  &&  compruebaCodigo(onOff, codigoIR, true) )
      {
        digitalWrite( rele, HIGH );
        digitalWrite( ledVerde, LOW );
        estadoLuz = true;
        Serial.println("Luz encendida"); // Depuracion
      }
        // Si la luz ya esta encendida...
      else if( estadoLuz )
      {
 
        // Se apaga la luz si se pulsa el boton "onOff"
        if( compruebaCodigo(onOff, codigoIR, true) )
        {
          digitalWrite( rele, LOW );
          digitalWrite( ledVerde, HIGH );
          estadoLuz = false;
          Serial.println("Luz apagada"); // Depuracion
        }
          // Se programa el apagado en 5 minutos si se pulsa el botón "apagadoAuto"
        else if( compruebaCodigo(apagadoAuto, codigoIR, false) )
        {
          apagadoProgramado(1);
        }
          // Se entra en el modo programación si se pulsa el botón "modoProgra"
        else if( compruebaCodigo(modoProgra, codigoIR, false) )
        {
 
          Serial.println("Modo programacion activado"); // Depuracion
 
          digitalWrite( buzzer, HIGH ); delay(10);
          digitalWrite( buzzer, LOW  ); delay(100);
 
          digitalWrite( ledRojo, HIGH );
          codigoIR = 0;
 
          do{
 
            if( irrecv.decode(&results) )
            {
              irrecv.resume();        // Se recibe el próximo valor
              codigoIR = results.value;   // Se guarda el valor recogido
              //Serial.print("Codigo IR: "); Serial.println(codigoIR); // Depuracion
 
              // Durante el modo programación, el botón "apagadoAuto" incrementa en 1 el multiplicador de tiempo:
              if( compruebaCodigo(apagadoAuto, codigoIR, false) )
              {
                multiplicador++;
 
                // Y se emite un pitido de aviso:
                digitalWrite( buzzer, HIGH ); delay(10);
                digitalWrite( buzzer, LOW  );
 
                // Si se llega al límite de tiempo, 60 minutos/12 pulsaciones, se avisa con un doble pitido:
                if( multiplicador == 13 )
                {
                  multiplicador--;
                  delay(20);
                  digitalWrite( buzzer, HIGH ); delay(10);
                  digitalWrite( buzzer, LOW  ); delay(15);
                  digitalWrite( buzzer, HIGH ); delay(10);
                  digitalWrite( buzzer, LOW  );
                };
 
                Serial.print("Contador de tiempo: "); Serial.print( ((multiplicador*tiempoApagado)/1000)/60 ); Serial.println(" minutos"); // Depuracion
              };
 
            };
 
          } while( !compruebaCodigo(modoProgra, codigoIR, false) );
 
          digitalWrite( ledRojo, LOW );
 
          if( multiplicador != 0 )
            apagadoProgramado(multiplicador);
          else
            Serial.println("Modo programacion cancelado"); // Depuracion
 
        };
 
      };
 
    };
 
  /************************************************ MODO DE CONTROL POR MANDO A DISTANCIA */
};
