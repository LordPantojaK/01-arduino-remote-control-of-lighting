# ARDUINO MINI PRO: CONTROL REMOTO DE ALUMBRADO - REMOTE CONTROL OF LIGHTING #

BLOG: http://giltesa.com/tag/pah/ <br />
Licendia: http://creativecommons.org/licenses/by-nc-sa/3.0/deed.es_ES

El siguiente código permite controlar el alumbrado de una habitación por medio de un relé.
Para ello dispone de diferentes modos de control y de diferentes modos de funcionamiento.
Puede controlarse manualmente mediante pulsaciones o mediante un mando a distancia por infrarrojos.
En ambos casos las funcionalidades son las mismas aunque varia la forma de acceder a ellas.


<br />
### CONTROL MANUAL MEDIANTE PULSACIONES: ###

Una pulsación corta enciende o apaga la luz.
> Dos pulsaciones cortas y seguidas y separadas entre ellas por un máximo de 1 segundo programaran el apagado automático de la luz en 5 minutos. Solo funciona si la luz esta encendida.
> Una pulsación corta desactivara el apagado automático y apagara la luz.

Una pulsación larga activa el modo programación, dentro del modo programación:
> Una pulsación corta aumenta en 5 minutos el tiempo de apagado, el tiempo podrá ser máximo de 1 hora.
> Una pulsación larga desactiva el modo programación y comienza el apagado automático con el tiempo programado.
> Una pulsación corta desactivara el apagado automático y apagara la luz.

<br />
### CONTROL MEDIANTE MANDO A DISTANCIA: ###

Se controlan todas las funciones mediante tres botones, sea el mando que sea.
> El primer botón:	Enciende o apaga la luz, también desconecta un apagado programado y apaga la luz a continuación.
> El segundo botón:	Activa el apagado automático de 5 minutos, o incrementa 5 minutos el tiempo dentro del modo programación.
> El tercer botón:	Entra y sale del modo programación.

NOTA:
> Normalmente los mandos a distancia mandan dos códigos distintos, el primero es el correspondiente al botón pulsado, el segundo es uno genérico entre todos los botones y que ha de ser desechado, este código sigue enviándose hasta que se deja de pulsar el botón y esto nos permite programar el código de forma sencilla.

> SIN CONTROLAR POR COMPLETO:
> > Sin embargo no todos los mandos funcionan así y hay casos especiales, por ejemplo con el mando de Microsoft MCE, cada botón tiene dos códigos validos y distintos del resto, y cuando es pulsado el botón se envía uno de esos dos códigos de forma duplicada y repetida hasta que deja de ser pulsado, por ello hay que comprobar ambos códigos y hay que configurar el programa para que solo se lean los códigos separados entre si por un periodo de tiempo determinado.


<br />
# NOTAS #
Para este proyecto hace falta la librería IRemote.h <br />
_http://www.arcfn.com/2009/08/multi-protocol-infrared-remote-library.html_

<br />
# CHANGE LOG #

2012/01/27 - v1.1:
  * Modificado el tiempo mínimo para la pulsación corta, de 100 a 20ms.
  * Añadido un aviso sonoro para advertir del apagado automático inminente.


2012/01/08 - v1.0:
  * Programa base.