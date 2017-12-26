/*
Proyecto: "Well tempered"
File: "graphics.scd"

Este código es llamado desde "main.scd"
*/




// Opciones de gráficas:
~post_window = false;
~freq_scope = false; // Analizador de espectro.
~gnuplot = true; // Abre gráficas gnuplot de quintas y terceras. Requiere quark "GNUplot" y gnuplot en el sistema.
~gp_fifths = nil;


/// FUNCIONES

// Devuelve un array con las medidas de un intervalo sobre cada una de las 12 notas (Para ser graficado, p.ej.)
~interval_12 = {arg interval, orden = 7; // El intervalo se mide en semitonos. P. ej. quinta = 7. "orden" se refiere a la ordenación de las quintas en el array: el entero indicará cuantas quintas saltarse (p. ej: "7" ordena los resultados por quintas.
	var array_cents = Array.newClear(12);
	var ordenado = 12.collect({arg i; ((orden*i)).mod(12)});
	ordenado.do({arg item, i;
		array_cents[i] = ((~tuning_notes[item+interval] - ~tuning_notes[item]) * 100) + (100 * interval);
	});
	array_cents;
};


// Devuelve un color en forma hexadecimal como String
~color_string = {arg color;
	"0x" ++ ((color.red.asInt<<16)+(color.green.asInt<<8)+color.blue.asInt).asHexString;
};

// Devuelve el color de una quinta según su desviación de la quinta justa (string de un hexadecimal)
~colorea_quinta = {arg quinta; // en cents
	var color, desviacion, blend;
	var max_desviacion = ~coma_pit/2; // máxima desviación de la consonancia en cents -> 1/2 de coma sintónica
	var consonance = ~quinta_justa;
	desviacion = (consonance - quinta).abs;
	blend = desviacion.linlin(0, max_desviacion, 0, 1);
	color = Color.new(0,255).blend(Color.new(255),blend);
	~color_string.value(color);
};



// Abre un gráfico de quintas en gnuplot.
// TODO: en p. 57 de "gnuplot in action (2nd edition) se explica como hacer un multiplot con un ejemplo. Útil para graficar notas de la escala, quintas, terceras mayores y terceras menores.

~gnuplot_fifths = {
	var string, file;

	// Escribimos el archivo de datos temporal
	file = File("gnuplot_temp","w");
	~interval_12.value(7, 7).do({arg i, index;
		file.write((index+1).asString ++ " " ++ i.asString ++ " " ++ ~colorea_quinta.value(i) ++ "\n");
	});
	file.close;

	// Si es la primera vez, enviamos toda la configuración a gnuplot. Si no, simplemente reploteamos.
	if (~gp_fifths == nil, {
		~gp_fifths = GNUPlot.new;
		// Configuración general de las gráficas:
		string = "set xlabel \"QUINTAS\"\n";
		string = string ++ "set title \"QUINTAS JUSTAS\" font \"sans, 20\"\n";
		string = string ++ "set ylabel \"TAMAÑO EN CENTS\"\n";
		string = string ++ "set boxwidth 0.75 relative\n";
		string = string ++ "set style fill solid 0.5\n";
		string = string ++ "set xtics (\"C\" 1, \"G\" 2, \"D\" 3, \"A\" 4, \"E\" 5, \"B\" 6, \"F#\" 7, \"C#\" 8, \"G#\" 9, \"D#\" 10, \"Bb\" 11, \"F\" 12)\n";

		// Órdenes de gráficas separadas por comas:
		string = string ++ "plot ";
		string = string ++ "[] [660:730] "; // usando un rango específico para la coordeanda "y".
		string = string ++ "\"" ++ File.getcwd ++ "/gnuplot_temp" ++ "\" " ++ "using 1:2:3 lc rgb variable " ++ "title " ++ "\"quintas temperamento actual\" " ++ "with boxes, ";
		string = string ++ ~quinta_justa.asString ++ " title \"quinta justa\"\ with line linewidth 3, ";
		string = string ++ "700 title \"quinta ET12\" with line linewidth 3\n";
		~gp_fifths.sendCmd(string);
	},{
		~gp_fifths.sendCmd("replot");
	});
};


// Muestra en pantalla la afinación actual
~print_tuning = {arg round = 0.1;

	if (~post_window == true, {
		var notes_name = ['C ','C#','D ','D#','E ','F ','F#','G ','G#','A ','A#','B '];
		var tn = ~tuning_notes;
		"D. ET    | Quintas      | Terceras M.  | Terceras m.  ".postln;
		"=========|==============|==============|==============".postln;

		notes_name.do({arg note, i;
			var temp;
			postln(
				note ++ "= " ++ (tn[i]*100).round(round) ++
				{var st = ""; (5-((tn[i]*100).round(round)).asString.size).do({st = st ++ " "}); st;
				}.value ++ "| " ++

				note ++ "-" ++ notes_name[(i+7).mod(12)] ++ "= " ++
				(((tn[i+7]-tn[i]+7)-((3/2).ratiomidi)*100)).round(round) ++
				{var st = "";
					(6-((((tn[i+7]-tn[i]+7)-((3/2).ratiomidi)*100)).round(round)).asString.size).do({
						st = st ++ " "
					}); st;
				}.value ++ "| " ++

				note ++ "-" ++ notes_name[(i+4).mod(12)] ++ "= " ++
				(((tn[i+4]-tn[i]+4)-((5/4).ratiomidi)*100)).round(round) ++
				{var st = "";
					(6-((((tn[i+4]-tn[i]+4)-((5/4).ratiomidi)*100)).round(round)).asString.size).do({
						st = st ++ " "
					}); st;
				}.value ++ "| " ++

				note ++ "-" ++ notes_name[(i+3).mod(12)] ++ "= " ++
				(((tn[i+3]-tn[i]+3)-((6/5).ratiomidi)*100)).round(round);

			);
		});

		"=========|==============|==============|==============".postln;
	});

	if (~gnuplot == true, {~gnuplot_fifths.value});
};