/*
Proyecto: "Well tempered"
File: "qsynth.scd"

Este código es llamado desde "main.scd"
*/




// Sintetizador Qsynth:
~qsynth = true; // Si "true", se usará Qsynth como sintetizador de sonido (asegurarse de que Qsynth está abierto).
~qs_program = 0; // Instrumento elegido en Qsynth.
~qs_midi_out; // Instancia de MIDIOut si "qsynth" está activado.
~qs_semitono_bend = 4096; // valor en "bend" de un semitono (100 cents) (para Qsynth)
~qs_notes = Array.newClear(128); // Array como el anterior pero para uso de Qsynth


// Activa un programa (instrumento) en el sintetizador qsynth
~qs_change_program = {arg program;
	10.do({arg chan; // polifonía de 10 notas máximo
		~qs_midi_out.program(chan, program);
	});
};


if (~qsynth == true, {
	~qs_midi_out = MIDIOut(0);
	~qs_midi_out.latency = 0;
	~qs_change_program.value(~qs_program); // por defecto pone el programa 1 en qsynth.
});