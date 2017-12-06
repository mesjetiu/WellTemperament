/*
    2017. Carlos Arturo Guerra Parra
    License GPL-3.0 or later (http://www.gnu.org/licenses/gpl-3.0).
*/



s.boot;


// Inicializa MIDI
(
MIDIClient.init;
MIDIIn.connectAll;
)


/// Carga todo el programa:

(
// Pueden cambiarse los siguientes parámetros:
var first_key = 36; // C1
var last_key = 84;  // C5
var keyboard_src = 1;  // G.O. de Content
var tune_up_key = 86;  // D5
var tune_down_key = 85;  // C#5

// Estructura de datos:
var notes; // Almacena en cada tecla MIDI el sintetizador que suena al pulsarse la tecla. Se elimina al levantar la tecla.
var tune_notes; // Almacena en cada tecla MIDI la desviación en cents respecto a ET12.
var count_notes = 0; // Lleva el recuento de notas que están activadas. Cuando es "0" la primera en activarse es la que pasa a ser afinada:
var note_to_tune = nil; // tecla que va a ser afinada

// Muestra en pantalla la afinación actual
var show_tune = {arg last_tuned = nil;
	("\nDesviaciones en cents respecto a ET12:\n" ++
	"C  = " ++ (tune_notes[0]*100).asString ++ "\n" ++
	"C# = " ++ (tune_notes[1]*100).asString ++ "\n" ++
	"D  = " ++ (tune_notes[2]*100).asString ++ "\n" ++
	"C# = " ++ (tune_notes[3]*100).asString ++ "\n" ++
	"E  = " ++ (tune_notes[4]*100).asString ++ "\n" ++
	"F  = " ++ (tune_notes[5]*100).asString ++ "\n" ++
	"F# = " ++ (tune_notes[6]*100).asString ++ "\n" ++
	"G  = " ++ (tune_notes[7]*100).asString ++ "\n" ++
	"G# = " ++ (tune_notes[8]*100).asString ++ "\n" ++
	"A  = " ++ (tune_notes[9]*100).asString ++ "\n" ++
	"A# = " ++ (tune_notes[10]*100).asString ++ "\n" ++
	"B  = " ++ (tune_notes[11]*100).asString ++ "\n"
	).postln;
};

// Aplica una diferencia de afinación en todas las octavas de una nota dada.
var retune_note = {arg note, dif_cents;
	var dif_tune = dif_cents / 100;
	var octavas_bajas, octavas_altas;
	octavas_bajas = (note,note-12..0);
	octavas_bajas.removeAt(0);
	octavas_altas = (note,note+12..127);
	(octavas_bajas++octavas_altas).do({arg i;
		tune_notes[i] = tune_notes[i] + dif_tune;
	});
};

// Resetea la afinación de una nota a un valor de desviación concreto (por defecto "0")
var reset_tune_note = {arg note, cents = 0;
	var octavas_bajas, octavas_altas;
	octavas_bajas = (note,note-12..0);
	octavas_bajas.removeAt(0);
	octavas_altas = (note,note+12..127);
	(octavas_bajas++octavas_altas).do({arg i;
		tune_notes[i] = cents/100;
	});
};

// Rutina para afinar al presionar las teclas asignadas
var routine_tune_up = Routine({
	var step = 0.1; // valor en cents de cada paso de afinación
	if (note_to_tune != nil, {
		var octavas_bajas = (note_to_tune, note_to_tune-12..0);
		var octavas_altas = (note_to_tune, note_to_tune+12..127);
		octavas_bajas.removeAt(0);
		loop{
			(octavas_bajas++octavas_altas).do({arg i;
				tune_notes[i] = tune_notes[i] + (step/100);
				if (notes[i] != nil, {
					notes[i].set(\freq, (i+tune_notes[i]).midicps);
				});
			});
			wait(0.05);
		};
	});
});

var routine_tune_down = Routine({
	var step = 0.1; // valor en cents de cada paso de afinación
	if (note_to_tune != nil, {
		var octavas_bajas = (note_to_tune, note_to_tune-12..0);
		var octavas_altas = (note_to_tune, note_to_tune+12..127);
		octavas_bajas.removeAt(0);
		loop{
			(octavas_bajas++octavas_altas).do({arg i;
				tune_notes[i] = tune_notes[i] - (step/100);
				if (notes[i] != nil, {
					notes[i].set(\freq, (i+tune_notes[i]).midicps);
				});
			});
			wait(0.05);
		};
	});
});

notes = Array.newClear(128);
tune_notes = Array.fill(128,0);


/// Funciones globales para acceso del usario

~enter_tune = {arg array_tune;
	array_tune.do({arg value, note;
		reset_tune_note.value(note, value);
	});
	notes.do({arg tono, index;
		if (tono != nil, {
			tono.set(\freq, (index+tune_notes[index]).midicps);
		});
	});
	show_tune.value;
};

~reset_tune_TE12 = {
	~enter_tune.value([0,0,0,0,0,0,0,0,0,0,0,0]);
};

/// FIN DE DECLARACIONES E INICIALIZACIONES DE VARIABLES////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////



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
	notes[chan] = Synth(\tono, [\freq, (chan+tune_notes[chan]).midicps]);
	if (count_notes == 0, {note_to_tune = chan}); // La primera nota pulsada en el teclado polifónicamente hablando, será la que se afinará y la introducimos en "note_to_tune"
	count_notes = count_notes + 1;
}, (first_key..last_key), keyboard_src);


MIDIdef.noteOff(\tecla_off, {
	arg val, chan, src;
	notes[chan].set(\gate, 0);
	notes[chan] = nil;
	count_notes = count_notes - 1;
	if (note_to_tune == chan, {note_to_tune = nil}); // Si la tecla levantada es la que estaba para afinar, la quitamos de "note_to_tune"
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
	show_tune.value;
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
	show_tune.value;
}, tune_down_key
);

MIDIdef.noteOn(\reset_TE12, {
	~reset_tune_TE12.value;
}, 96 // Responde sólo a la tecla C6
);

show_tune.value;
)

~enter_tune.value([1,3,20,1,0,-1,3,2,5,4,3,1]);

~reset_tune.value;