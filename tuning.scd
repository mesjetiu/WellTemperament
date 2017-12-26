/*
Proyecto: "Well tempered"
File: "tuning.scd"

Este código es llamado desde "main.scd"
*/

// Variables
~quinta_justa = (3/2).ratiomidi*100;
~coma_pit = (~quinta_justa * 12) - (700 * 12);
~tuning_notes = Array.fill(128,0); // Array que almacena en cada valor MIDI la desviación en cents respecto a ET12.

// Aplica una diferencia de afinación en todas las octavas de una nota dada.
~retune_note = {arg note, dif_cents;
	var dif_tune = dif_cents / 100;
	var octavas_bajas, octavas_altas;
	octavas_bajas = (note,note-12..0);
	octavas_bajas.removeAt(0);
	octavas_altas = (note,note+12..127);
	(octavas_bajas++octavas_altas).do({arg i;
		~tuning_notes[i] = ~tuning_notes[i] + dif_tune;
		if ((~notes[i] != nil) && (~synth_internal != nil), {
			~notes[i].set(\freq, (i+~tuning_notes[i]).midicps);
		});
		if ((~qs_notes[i] != nil) && (~qsynth == true), {
			~qs_midi_out.bend(~qs_notes[i], 8192 + (~tuning_notes[i]*4096));
		});
	});
};

// Resetea la afinación de una nota a un valor de desviación concreto (por defecto "0")
~reset_tune_note = {arg note, cents = 0;
	var octavas_bajas, octavas_altas;
	if (~tune_octaves == true, {
		octavas_bajas = (note,note-12..0);
		octavas_bajas.removeAt(0);
		octavas_altas = (note,note+12..127);
		(octavas_bajas++octavas_altas).do({arg i;
			~tuning_notes[i] = cents/100;
		});
	}, {
		~tuning_notes[note] = cents/100;
	});
};

// Función para repartir el lobo entre las quintas existentes entre las dos primeras notas pulsadas.
~partitio = {
	if ((~first_pushed_notes[0] != nil) && (~first_pushed_notes[1] != nil), {
		var note_1, note_2, note_temp; // las notas que quedarán fijas.
		var fifths_num = 1; // Número de quintas a repartir;
		var notes_to_tune = Array.newClear(12); // notas a afinar
		var wolf; // Cantidad de error respecto a ET12 a repartir entre las quintas
		// reducimos a la octava 1 ambas notas y las almacenamos
		note_1 = (~first_pushed_notes[0],(~first_pushed_notes[0]-12)..0).last;
		note_2 = (~first_pushed_notes[1],(~first_pushed_notes[1]-12)..0).last;
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
		wolf = ((~tuning_notes[note_2]) - (~tuning_notes[note_1])) * 100;
		wolf = wolf / fifths_num; // wolf ahora almacena el error de una sóla quinta
		// Afinamos las quintas
		notes_to_tune.do({arg i, n;
			if (i != nil, {~reset_tune_note.value(i, wolf*(n+1))});
		});
		~print_tuning.value;
	});
};

// Rutina para afinar al presionar las teclas asignadas
~routine_tune_up = Routine({
	var step = 0.1; // valor en cents de cada paso de afinación
	while({~first_pushed_notes[0] != nil}, {
		~retune_note.value(~first_pushed_notes[0], step);
		wait(0.05);
	});
});

~routine_tune_down = Routine({
	var step = 0.1; // valor en cents de cada paso de afinación
	while ({~first_pushed_notes[0] != nil}, {
		~retune_note.value(~first_pushed_notes[0], step*(-1));
		wait(0.05);
	});
});


/// Funciones globales para acceso del usario

~enter_tune = {arg array_tune;
	array_tune.do({arg value, note;
		~reset_tune_note.value(note, value);
	});
	~notes.do({arg tono, index;
		if (tono != nil, {
			tono.set(\freq, (index+~tuning_notes[index]).midicps);
		});
	});
	~print_tuning.value;
};

~reset_tune_TE12 = {
	~enter_tune.value([0,0,0,0,0,0,0,0,0,0,0,0]);
};
