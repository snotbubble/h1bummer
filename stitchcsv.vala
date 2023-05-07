// stitch csv files together
// by cpbrown 2023
//
// usage: ./stitchcsv file1.csv file2.csv file3.csv ...
// hardcoded output to ./h1b.csv, this gets overwritten without warning

using Gtk;
string fixcsvrow (string r) {
	if (r != null) {
		bool k = true;
		string o = r;
		unichar h;
		for (int i = 0; o.get_next_char (ref i, out h);) {
			int s = i - 1;
			if (h == '\"') {
				if ( k == true ) { k = false; } else { k = true; }
				o = o.splice(s, i, "");
				i = i - 1;
			}
			if (h == ',' && k) { o = o.splice(s, i, ";"); }
		}
		return o;
	} else { return ""; }
}
void main(string[] args) {
	string dd = GLib.Environment.get_current_dir();
	string[] o = {};
	for (int i = 0; i < args.length; i++) {
		print("args[%d] = %s\n",i,args[i]);
	}
	File argf;
	if (args.length >= 1) {
		for (int i = 1; i < args.length; i ++) {
			bool rtd = false;
			string ds = dd.concat("/",args[i]);
			print("loading file = %s\n",ds);
			argf = File.new_for_path (ds);
			if (argf.query_exists()) {
				GLib.FileStream fstr = null;
				fstr = FileStream.open(ds,"r");
				string l = fstr.read_line();
				if (l != null) {
					string[] cols = l.split(";");
					if (cols.length < 2) {
						l = fixcsvrow(l);
						rtd = true;
					}
				}
				while (l != null) {
					if (l != "") { 
						if (rtd) {
							o += fixcsvrow(l);
						} else {
							o += l;
						} 
					} else { break; } 
					l = fstr.read_line(); 
				}
			}
		}
	}
	if (o.length > 0) {
		bool allgood = true;
		File ouf = File.new_for_path (dd.concat("/h1b.csv"));
		print("output file is: %s\n",ouf.get_path());
		FileOutputStream oustr = null;
		try {
			oustr = ouf.replace (null, false, FileCreateFlags.PRIVATE);
			allgood = true;
		} catch (Error e) {
			print ("Error: couldn't make outputstream.\n\t%s\n", e.message);
		}
		if (allgood) {
			for (int i = 0; i < o.length; i++) {
				try {
					oustr.write(o[i].data);
					oustr.write("\n".data);
				} catch (Error e) { 
					string oufs = ouf.get_path();
					print("Error: couldn't write to file: %s\n",oufs);
				}
			}
		}
	}
}