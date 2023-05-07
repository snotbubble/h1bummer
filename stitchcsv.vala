using Gtk;
void main(string[] args) {
	string dd = GLib.Environment.get_current_dir();
	string[] o = {};
	for (int i = 0; i < args.length; i++) {
		print("args[%d] = %s\n",i,args[i]);
	}
	File argf;
	if (args.length >= 1) {
		for (int i = 1; i < args.length; i ++) {
			string ds = dd.concat("/",args[i]);
			print("loading file = %s\n",ds);
			argf = File.new_for_path (ds);
			if (argf.query_exists()) {
				GLib.FileStream fstr = null;
				fstr = FileStream.open(ds,"r");
				string l = fstr.read_line();
				while (l != null) {
					if (l != "") { o += l; } else { break; } 
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