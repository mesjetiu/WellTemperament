/*
Proyecto: "Well tempered"
File: "midi.scd"

Este código es llamado desde "main.scd"
*/




// Teclas del teclado MIDI asociadas a funciones (pueden asociarse a conveniencia):
~first_key = 36; // C1
~last_key = 84;  // C5
~keyboard_src = nil;  // Si "nil", admite todos los canales (En el caso de tener varios teclados, especificar un canal si se quiere)
~tune_up_key = 86;  // D5
~tune_down_key = 85;  // C#5
~partitio_key = 87;  // D#
~tune_octaves = true; // Afina todas las octavas de la nota que afinamos.

// Estructura de datos para MIDI:
~notes = Array.newClear(128); // Array que almacena en cada tecla MIDI el sintetizador que suena al pulsarse la tecla. Se elimina al levantar la tecla.
~count_pushed_notes = 0; // Lleva el recuento de notas que están pulsadas.
~first_pushed_notes = Array.newClear(2); // Array que almacena las 2 primeras notas pulsadas. [0] se usa para afinar la primera nota pulsada. [0] y [1] se usan para realizar el reparto entre las quintas intermedias.


/// Preparación del teclado MIDI ///////////////////////////////////////////////////////////////////////////

// Parte del teclado que se usa para tocar música (dejamos libre la quinta octava)

MIDIdef.noteOn(\tecla_on, {
	arg val, chan, src;
	if ((~qs_notes[chan] == nil) && (~qsynth == true), {
		var qs_channel = ~count_pushed_notes; // Canal de Qsynth donde se enviará la nota (en el caso de estar activada la opción "qsynth")
		if (qs_channel > 9, {qs_channel = 9}); // Nos aseguramos de no usar más de 10 canales
		~qs_midi_out.bend(qs_channel, 8192 + (~tuning_notes[chan]*~qs_semitono_bend));
		~qs_midi_out.noteOn(qs_channel, chan);
		~qs_notes[chan] = qs_channel;
	});

	if ((~notes[chan] == nil) && (~synth_internal != nil), {
		~notes[chan] = Synth(~synth_internal, [\freq, (chan+~tuning_notes[chan]).midicps]);
	});

	if (~count_pushed_notes == 0, {~first_pushed_notes[0] = chan});
	if (~count_pushed_notes == 1, {~first_pushed_notes[1] = chan});
	~count_pushed_notes = ~count_pushed_notes + 1;
}, (~first_key..~last_key), ~keyboard_src);


MIDIdef.noteOff(\tecla_off, {
	arg val, chan, src;
	if ((~qsynth == true) && (~qs_notes[chan] != nil), {
		~qs_midi_out.noteOff(~qs_notes[chan], chan);
		~qs_notes[chan] = nil;
	});
	if ((~synth_internal != nil) && (~notes[chan] != nil), {
		~notes[chan].set(\gate, 0);
		~notes[chan] = nil;
	});

	if (~first_pushed_notes[0] == chan, {~first_pushed_notes[0] = nil});
	if (~first_pushed_notes[1] == chan, {~first_pushed_notes[1] = nil});
	~count_pushed_notes = ~count_pushed_notes - 1;
}, (~first_key..~last_key), ~keyboard_src);

// Teclas para afinar
// Al igual que almacenamos externamente los sintetizadores que se inician con \tecla_on y se terminan con \tecla_off, hay que crear unas variables externas para almacenar las rutinas de afinación para \tune_up_on, \tune_up_off, \tune_down_on y \tune_down_off

MIDIdef.noteOn(\tune_up_on, {
	arg val, chan, src;
	if (~notes[chan] == nil, {
		~routine_tune_up.reset;
		~routine_tune_up.play;
		~notes[chan] = chan;
	});
}, ~tune_up_key
);

MIDIdef.noteOff(\tune_up_off, {
	arg val, chan, src;
	if (~notes[chan] != nil, {
		~routine_tune_up.stop;
		~print_tuning.value;
		~notes[chan] = nil;
	});
}, ~tune_up_key
);

MIDIdef.noteOn(\tune_down_on, {
	arg val, chan, src;
	if (~notes[chan] == nil, {
		~routine_tune_down.reset;
		~routine_tune_down.play;
		~notes[chan] = chan;
	});
}, ~tune_down_key
);

MIDIdef.noteOff(\tune_down_off, {
	arg val, chan, src;
	if (~notes[chan] != nil, {
		~routine_tune_down.stop;
		~print_tuning.value;
		~notes[chan] = nil;
	});
}, ~tune_down_key
);

MIDIdef.noteOn(\partitio_on, {
	arg val, chan, src;
	if (~notes[chan] == nil, {
		~partitio.value;
		~notes[chan] = chan;
	});
}, ~partitio_key
);

MIDIdef.noteOff(\partitio_off, {
	arg val, chan, src;
	if (~notes[chan] != nil, {
		~notes[chan] = nil;
	});
}, ~partitio_key
);

MIDIdef.noteOn(\reset_TE12_on, {
	arg val, chan, src;
	if (~notes[chan] == nil, {
		~reset_tune_TE12.value;
		~notes[chan] = chan;
	});
}, 96 // Responde sólo a la tecla C6
);

MIDIdef.noteOff(\reset_TE12_off, {
	arg val, chan, src;
	if (~notes[chan] != nil, {
		~notes[chan] = nil;
	});
}, 96 // Responde sólo a la tecla C6
);

MIDIdef.program(\program_change, {
	arg val, chan, src;
	~qs_change_program.value(val);
}
);