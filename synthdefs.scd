/*
Proyecto: "Well tempered"
File: "synthdefs.scd"

Este código es llamado desde "main.scd"
*/

// Sintetizador a usasr:
~synth_internal = \tono; // Si contiene el símbolo de un sintetizador de Supercollider, se usará para salida de sonido. Si es "nil" no sonará ningún sintetizador de Supercollider.




// Definimos el sintetizador de notas. Consta de 10 armónicos, cada uno con un volumen independiente y modificable en tiempo real.
SynthDef(\tono, {
	arg freq = 440, amp = 0.5, gate = 1, har1=1, har2=0.5, har3=0.4, har4=0.2, har5=0.1, har6=0.1, har7=0.07, har8=0.06, har9=0.05, har10=0.04;
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
	sig = sig * 0.08 * amp * env;
	Out.ar(0, sig!2);
}).add;