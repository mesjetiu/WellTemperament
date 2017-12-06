s.boot;

(
MIDIClient.init;
MIDIIn.connectAll;
)

MIDIdef.trace(true);


// Definimos el sintetizador de notas. Consta de 10 armónicos, cada uno con un volumen independiente y modificable en tiempo real.
(
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
	sig = sig * 0.1 * amp * env;
	Out.ar(0, sig!2);
}).add;
)


(
var notes; // Almacena en cada tecla MIDI el sintetizador que suena al pulsarse la tecla. Se elimina al levantar la tecla.
var tune_notes; // Almacena en cada tecla MIDI la desviación en cents respecto a ET12.
var note_C, note_Cs, note_D, note_Ds, note_E, note_F, note_Fs, note_G, note_Gs, note_A, note_As, note_B;

// Aplica una diferencia de afinación en todas las octavas de una nota dada.
var retune_note = {arg note, dif_cents;
	var dif_tune = dif_cents / 100;
	note.do({arg i;
		tune_notes[i] = tune_notes[i] + dif_tune;
	})
};

// Resetea la afinación de una nota a un valor de desviación concreto (por defecto "0")
var reset_tune_note = {arg note, cents = 0;
	note.do({arg i;
		tune_notes[i] = cents;
	});
};


notes = Array.newClear(128);
tune_notes = Array.fill(128,0);

// Cada nota corresponde a todas las teclas homónimas del teclado (en un array)
note_C = (0,12..127);
note_Cs = (1,13..127);
note_D = (2,14..127);
note_Ds = (3,15..127);
note_E = (4,16..127);
note_F = (5,17..127);
note_Fs = (6,18..127);
note_G = (7,19..127);
note_Gs = (8,20..127);
note_A = (9,21..127);
note_As = (10,22..127);
note_B = (11,23..127);

/// FIN DE DECLARACIONES E INICIALIZACIONES ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////



// Ejemplo de cambio en la afinación de una nota
retune_note.value(note_C, -21);
reset_tune_note.value(note_D, 2);

tune_notes;
)

Array.fill(10,nil)