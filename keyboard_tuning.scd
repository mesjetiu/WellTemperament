/*
    2017. Carlos Arturo Guerra Parra (carlosarturoguerra@gmail.com)
    License GPL-3.0 or later (http://www.gnu.org/licenses/gpl-3.0).
*/



/*
El siguiente programa permite temperar el teclado desde el mismo teclado usando dos teclas reservadas para subir y bajar el tono respectivamente mientras se toca.
Partimos del temperamento igual. Para reafinar una nota (y todas sus octavas), púlsese la tecla correspondiente asegurándose de que no hay ninguna pulsada en ese momento. Una vez pulsada y sin soltarse pueden pulsarse otras para usarlas de referencia. La tecla D5 sube el tono y C#5 baja el tono (estas teclas pueden cambiarse) mientras son mantenidas. Cada vez que se sueltan las teclas de afinación se muestra en la ventana "Post window" el estado de la afinación.
La tecla C6 resetea la afinación a temperamento igual.
*/


(
s.boot;

// Inicializamos MIDI
MIDIClient.init;
MIDIIn.connectAll;
)


/// Carga todo el programa:

(
// Teclas del teclado MIDI asociadas a funciones (pueden asociarse a conveniencia):
var first_key = 36; // C1
var last_key = 84;  // C5
var keyboard_src = 1;  // G.O. de Content
var tune_up_key = 86;  // D5
var tune_down_key = 85;  // C#5
var partitio_key = 87;  // D#
var tune_octaves = true; // Afina todas las octavas de la nota que afinamos.

// Estructura de datos:
var notes = Array.newClear(128); // Array que almacena en cada tecla MIDI el sintetizador que suena al pulsarse la tecla. Se elimina al levantar la tecla.
var tuning_notes = Array.fill(128,0); // Array que almacena en cada tecla MIDI la desviación en cents respecto a ET12.
var count_pushed_notes = 0; // Lleva el recuento de notas que están pulsadas.
var first_pushed_notes = Array.newClear(2); // Array que almacena las 2 primeras notas pulsadas. [0] se usa para afinar la primera nota pulsada. [0] y [1] se usan para realizar el reparto entre las quintas intermedias.

// Sintetizador Qsynth:
var qsynth = true; // Si "true", se usará Qsynth como sintetizador de sonido (asegurarse de que Qsynth está abierto).
var qs_program = 0; // Instrumento elegido en Qsynth.
var qs_midi_out; // Instancia de MIDIOut si "qsynth" está activado.


// Muestra en pantalla la afinación actual
var print_tuning = {arg round = 0.1;
	var tn = tuning_notes;
	var name = ['C ','C#','D ','D#','E ','F ','F#','G ','G#','A ','A#','B '];
	"D. ET    | Quintas      | Terceras M.  | Terceras m.  ".postln;
	"=========|==============|==============|==============".postln;

	name.do({arg note, i;
		var temp;
		postln(
			note ++ "= " ++ (tn[i]*100).round(round) ++
			{var st = ""; (5-((tn[i]*100).round(round)).asString.size).do({st = st ++ " "}); st;
			}.value ++ "| " ++

			note ++ "-" ++ name[(i+7).mod(12)] ++ "= " ++
			(((tn[i+7]-tn[i]+7)-((3/2).ratiomidi)*100)).round(round) ++
			{var st = "";
				(6-((((tn[i+7]-tn[i]+7)-((3/2).ratiomidi)*100)).round(round)).asString.size).do({
					st = st ++ " "
				}); st;
			}.value ++ "| " ++

			note ++ "-" ++ name[(i+4).mod(12)] ++ "= " ++
			(((tn[i+4]-tn[i]+4)-((5/4).ratiomidi)*100)).round(round) ++
			{var st = "";
				(6-((((tn[i+4]-tn[i]+4)-((5/4).ratiomidi)*100)).round(round)).asString.size).do({
					st = st ++ " "
				}); st;
			}.value ++ "| " ++

			note ++ "-" ++ name[(i+4).mod(12)] ++ "= " ++
			(((tn[i+3]-tn[i]+3)-((6/5).ratiomidi)*100)).round(round);

		);
	});

	"=========|==============|==============|==============".postln;

	"OK"
};

// Aplica una diferencia de afinación en todas las octavas de una nota dada.
var retune_note = {arg note, dif_cents;
	var dif_tune = dif_cents / 100;
	var octavas_bajas, octavas_altas;
	if (tune_octaves == true, {
		octavas_bajas = (note,note-12..0);
		octavas_bajas.removeAt(0);
		octavas_altas = (note,note+12..127);
		(octavas_bajas++octavas_altas).do({arg i;
			tuning_notes[i] = tuning_notes[i] + dif_tune;
			if (notes[i] != nil, {
				notes[i].set(\freq, (i+tuning_notes[i]).midicps);
			});
		});
	}, {
		tuning_notes[note] = tuning_notes[note] + dif_tune;
		if (notes[note] != nil, {
			notes[note].set(\freq, (note+tuning_notes[note]).midicps);
		});
	});
};

// Resetea la afinación de una nota a un valor de desviación concreto (por defecto "0")
var reset_tune_note = {arg note, cents = 0;
	var octavas_bajas, octavas_altas;
	if (tune_octaves == true, {
		octavas_bajas = (note,note-12..0);
		octavas_bajas.removeAt(0);
		octavas_altas = (note,note+12..127);
		(octavas_bajas++octavas_altas).do({arg i;
			tuning_notes[i] = cents/100;
		});
	}, {
		tuning_notes[note] = cents/100;
	});
};

// Función para repartir el lobo entre las quintas existentes entre las dos primeras notas pulsadas.
var partitio = {
	if ((first_pushed_notes[0] != nil) && (first_pushed_notes[1] != nil), {
		var note_1, note_2, note_temp; // las notas que quedarán fijas.
		var fifths_num = 1; // Número de quintas a repartir;
		var notes_to_tune = Array.newClear(12); // notas a afinar
		var wolf; // Cantidad de error respecto a ET12 a repartir entre las quintas
		// reducimos a la octava 1 ambas notas y las almacenamos
		note_1 = (first_pushed_notes[0],(first_pushed_notes[0]-12)..0).last;
		note_2 = (first_pushed_notes[1],(first_pushed_notes[1]-12)..0).last;
		// Calculamos las notas que hay que afinar
		note_temp = note_1 + 7;
		if (note_temp > 11, {note_temp = note_temp - 12});
		({note_temp != note_2}).while({
			notes_to_tune[fifths_num-1] = note_temp;  // y almacenamos las notas a afinar
			note_temp = note_temp + 7; // subimos note_1 una quinta
			if (note_temp > 11, {note_temp = note_temp - 12});
			fifths_num = fifths_num + 1; // vamos contando las quintas a afinar
		});
		// Calculamos la cantidad de cents que hay que mover cada quinta
		wolf = ((tuning_notes[note_2]) - (tuning_notes[note_1])) * 100;
		wolf = wolf / fifths_num; // wolf ahora almacena el error de una sóla quinta
		// Afinamos las quintas
		notes_to_tune.do({arg i, n;
			if (i != nil, {reset_tune_note.value(i, wolf*(n+1))});
		});
		print_tuning.value;
	});
};

// Rutina para afinar al presionar las teclas asignadas
var routine_tune_up = Routine({
	var step = 0.1; // valor en cents de cada paso de afinación
	if (first_pushed_notes[0] != nil, {
		loop{
			retune_note.value(first_pushed_notes[0], step);
			wait(0.05);
			};
	});
});

var routine_tune_down = Routine({
	var step = 0.1; // valor en cents de cada paso de afinación
	if (first_pushed_notes[0] != nil, {
		loop{
			retune_note.value(first_pushed_notes[0], step*(-1));
			wait(0.05);
			};
	});
});


/// Funciones globales para acceso del usario

~enter_tune = {arg array_tune;
	array_tune.do({arg value, note;
		reset_tune_note.value(note, value);
	});
	notes.do({arg tono, index;
		if (tono != nil, {
			tono.set(\freq, (index+tuning_notes[index]).midicps);
		});
	});
	print_tuning.value;
};

~reset_tune_TE12 = {
	~enter_tune.value([0,0,0,0,0,0,0,0,0,0,0,0]);
};


/// FIN DE DECLARACIONES E INICIALIZACIONES DE VARIABLES////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

if (qsynth == true, {
	qs_midi_out = MIDIOut(0);
	qs_midi_out.latency = 0;
	qs_midi_out.program(0, qs_program);
	qs_midi_out.program(15, qs_program);
});


// Definimos el sintetizador de notas. Consta de 10 armónicos, cada uno con un volumen independiente y modificable en tiempo real.

SynthDef(\tono, {
	arg freq = 440, amp = 0.5, gate = 1, har1=1, har2=1, har3=1, har4=1, har5=1, har6=1, har7=1, har8=1, har9=1, har10=1;
	var sig, env, harm;
	env = Env.asr(0.01, 1, 0.2).kr(2, gate);
	sig = SinOsc.ar(freq,0,har1);
	sig = sig + SinOsc.ar(freq*2,0,har2);
	sig = sig + SinOsc.ar(freq*3,0,har3);
	sig = sig + SinOsc.ar(freq*4,0,har4);
	sig = sig + SinOsc.ar(freq*5,0,har5);
	sig = sig + SinOsc.ar(freq*6,0,har6);
	sig = sig + SinOsc.ar(freq*7,0,har7);
	sig = sig + SinOsc.ar(freq*8,0,har8);
	sig = sig + SinOsc.ar(freq*9,0,har9);
	sig = sig + SinOsc.ar(freq*10,0,har10);
	sig = sig * 0.005 * amp * env;
	Out.ar(0, sig!2);
}).add;

/// Preparación del teclado MIDI ///////////////////////////////////////////////////////////////////////////

// Parte del teclado que se usa para tocar música (dejamos libre la quinta octava)

MIDIdef.noteOn(\tecla_on, {
	arg val, chan, src;
	var qs_channel = 0; // Canal de Qsynth donde se enviará la nota (en el caso de estar activada la opción "qsynth")
	if (count_pushed_notes == 0, {first_pushed_notes[0] = chan; qs_channel = 15});
	if (count_pushed_notes == 1, {first_pushed_notes[1] = chan});
	count_pushed_notes = count_pushed_notes + 1;
	if (qsynth == true, {
		qs_midi_out.noteOn(qs_channel, chan);
	}, {
		notes[chan] = Synth(\tono, [\freq, (chan+tuning_notes[chan]).midicps]);
	});
}, (first_key..last_key), keyboard_src);


MIDIdef.noteOff(\tecla_off, {
	arg val, chan, src;
	var qs_channel = 0;
	if (first_pushed_notes[0] == chan, {first_pushed_notes[0] = nil; qs_channel = 15});
	if (first_pushed_notes[1] == chan, {first_pushed_notes[1] = nil});
	if (qsynth == true, {
		qs_midi_out.noteOff(qs_channel, chan);
	}, {
		notes[chan].set(\gate, 0);
		notes[chan] = nil;
	});
	count_pushed_notes = count_pushed_notes - 1;
}, (first_key..last_key), keyboard_src);

// Teclas para afinar
// Al igual que almacenamos externamente los sintetizadores que se inician con \tecla_on y se terminan con \tecla_off, hay que crear unas variables externas para almacenar las rutinas de afinación para \tune_up_on, \tune_up_off, \tune_down_on y \tune_down_off

MIDIdef.noteOn(\tune_up_on, {
	arg val, chan, src;
	routine_tune_up.reset;
	routine_tune_up.play;
}, tune_up_key
);

MIDIdef.noteOff(\tune_up_off, {
	arg val, chan, src;
	routine_tune_up.stop;
	print_tuning.value;
}, tune_up_key
);

MIDIdef.noteOn(\tune_down_on, {
	arg val, chan, src;
	routine_tune_down.reset;
	routine_tune_down.play;
}, tune_down_key
);

MIDIdef.noteOff(\tune_down_off, {
	arg val, chan, src;
	routine_tune_down.stop;
	print_tuning.value;
}, tune_down_key
);

MIDIdef.noteOn(\partitio, {
	partitio.value;
}, partitio_key
);

MIDIdef.noteOn(\reset_TE12, {
	~reset_tune_TE12.value;
}, 96 // Responde sólo a la tecla C6
);

print_tuning.value;
)







~enter_tune.value([1,3,20,1,0,-1,3,2,5,4,3,1]);

~reset_tune.value;