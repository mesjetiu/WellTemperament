/*
2017. Carlos Arturo Guerra Parra (carlosarturoguerra@gmail.com)
License GPL-3.0 or later (http://www.gnu.org/licenses/gpl-3.0).

El siguiente programa permite temperar el teclado desde el mismo teclado usando dos teclas reservadas para subir y bajar el tono respectivamente mientras se toca.
Partimos del temperamento igual. Para reafinar una nota (y todas sus octavas), púlsese la tecla correspondiente asegurándose de que no hay ninguna pulsada en ese momento. Una vez pulsada y sin soltarse pueden pulsarse otras para usarlas de referencia. La tecla D5 sube el tono y C#5 baja el tono (estas teclas pueden cambiarse) mientras son mantenidas. Cada vez que se sueltan las teclas de afinación se muestra en la ventana "Post window" el estado de la afinación.
La tecla C6 resetea la afinación a temperamento igual.

DEPENDENCIAS:
* Quark "GNUPlot"
* gnuplot instalado en el sistema

OPCIONAL:
* fluidsynth (qsynth) como sintetizador externo
*/






(
s.boot;

// Inicializamos MIDI
if (MIDIClient.initialized == false, {
	MIDIClient.init;
	MIDIIn.connectAll;
});

/////////////////////// Archivos con declaraciones de variables y funciones.

"tuning.scd".loadRelative;
"midi.scd".loadRelative;
"synthdefs.scd".loadRelative;
"qsynth.scd".loadRelative;
"graphics.scd".loadRelative;

/////////////////////// Hasta aquí declaraciones de variables y funciones.


if (~freq_scope == true, {FreqScope.new});
~print_tuning.value;
)