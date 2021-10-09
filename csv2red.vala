
public static int main (string[] args) {
	var nottesting = true;
	var f = File.new_for_path ("out.rb");
	try {
		f.delete ();
	} catch (Error e) {
		print ("Error: %s\n", e.message);
	}
	if (nottesting == false) {
		string test = "this, is, a, \"retarded, csv\", row";
		test = test.splice(4, 5, ";");
		print ("%s\n", test);
	}
	if (nottesting) {
		FileStream stream = FileStream.open ("src.csv", "r");
		FileStream o = FileStream.open ("out.rb", "a");
		string line = stream.read_line();
		while (line != null) {
			if (line != "") {
				var k = true;
				unichar h;
				for (int i = 0; line.get_next_char (ref i, out h);) {
					int e = i + 1;
					int s = i - 1;
					if (h == '"') {
						if ( k == true ) { k = false; } else { k = true; }
						line = line.splice(s, i, "");
						i = i - 1;
					}
					if (h == ',' && k) { line = line.splice(s, i, ";"); }
				}
				//o.write(line.data);
				o.write("[ ".data);
				string[] cols = line.split(";");
				for (int l = 0; l < cols.length; l++) {
					string redline = ("\"" + cols[l] + "\" ");
					uint8[] buf = redline.data;
					o.write(buf);
				}
				o.write("]\n".data);
			}
			line = stream.read_line();
		}
	}
	return 0;
}