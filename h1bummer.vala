using Gtk;

bool doup;
Gtk.ListStore stor;
Gtk.TreeIter itera;
GLib.Value vclass;

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

// 0 5  visa class
// 1 6  job title
// 2 8  soc title
// 3 10 start date
// 4 19 employer
// 5 23 employer city
// 6 24 employer state
// 7 71 pay from
// 8 72 pay to
// 9 73 pay unit

void loaddat () {
	FileStream stream = FileStream.open ("./source/h1b.csv", "r");
	string line = stream.read_line();
	bool isretardedcsv = false;
	if (line != "") {
		string[] h = line.split(";");
		if (h.length < 50) {
			line = fixcsvrow(line); 
			h = line.split(";");
			isretardedcsv = true;
		}
		for (int g = 0; g < h.length; g++) {
			print("[%d] %s\n",g,h[g]);
		}
		int r = 0;
		while (line != null) {
			if (line != "") {
				if (r > 0) { 
					if (isretardedcsv) { line = fixcsvrow(line); }
					//print("[%d] prepared line: %s\n",r,line);
					string[] cols = line.split(";");
					//if (cols.length > 60) { print("col count is %d\n",cols.length); break; }
					stor.append(out itera);
					stor.set(itera,0,cols[5],1,cols[6],2,cols[8],3,cols[10],4,cols[19],5,cols[23],6,cols[24],7,cols[71],8,cols[72],9,cols[73]);
				}
			} else { break; }
			line = stream.read_line();
			r += 1;
			if (r >= 500000) { break; }
		}
	}
}

public class h1bummer : Gtk.Application {
	construct {
		application_id = "com.h1bummer.h1bummer";
		flags = ApplicationFlags.FLAGS_NONE;
	}
}

// the window

public class qwin : Gtk.ApplicationWindow {
	public qwin (Gtk.Application h1bummer) {Object (application: h1bummer);}
	construct {
		doup = false;
		this.title = "h1bummer";
		this.close_request.connect((e) => { return false; } );
		Gtk.Label titlelabel = new Gtk.Label("h1bummer");
		Gtk.HeaderBar iobar = new Gtk.HeaderBar();
		iobar.show_title_buttons = false;
		iobar.set_title_widget(titlelabel);
		this.set_titlebar(iobar);
		this.set_default_size(720, (720 - 46));
		Gtk.Box container = new Gtk.Box(VERTICAL,0);
		Gtk.Box control = new Gtk.Box(HORIZONTAL,0);
		Gtk.Entry vcfilt = new Gtk.Entry(); 
		control.append(vcfilt);
		Gtk.Box content = new Gtk.Box(VERTICAL,0);
		content.hexpand = true;
		content.vexpand = true;
		Gtk.ScrolledWindow contentscroll = new Gtk.ScrolledWindow();
		stor = new Gtk.ListStore(10,
			typeof (string), 
			typeof (string), 
			typeof (string), 
			typeof (string), 
			typeof (string), 
			typeof (string), 
			typeof (string), 
			typeof (string), 
			typeof (string), 
			typeof (string));
		loaddat();
		Gtk.TreeView nxn = new Gtk.TreeView();
		Gtk.TreeModelFilter tmf = new Gtk.TreeModelFilter(stor,null);
		Gtk.TreeModelSort tms = new Gtk.TreeModelSort.with_model(tmf);
		nxn.set_model(tms);
		tmf.set_visible_func((model,iter) => {
			if (vcfilt.text == "") { return true; }
			vclass = new GLib.Value(typeof (string));
			model.get_value(iter,0,out vclass);
			return vclass.get_string().contains(vcfilt.text);
		});
		vcfilt.changed.connect(() => {
			if (doup && vcfilt.text.strip() != "") {
				tmf.refilter();
				print("setting column %d filter to %s\n",0,vcfilt.text);
			}
		});
		nxn.insert_column_with_attributes(-1, "VISA CLASS", new Gtk.CellRendererText(),"text",0);
		//nxn.get_column(0).set_sort_column_id(0);
		nxn.insert_column_with_attributes(-1, "JOB TITLE", new Gtk.CellRendererText(),"text",1);
		//nxn.get_column(1).set_sort_column_id(1);
		nxn.insert_column_with_attributes(-1, "SOC TITLE", new Gtk.CellRendererText(),"text",2);
		//nxn.get_column(2).set_sort_column_id(2);
		nxn.insert_column_with_attributes(-1, "START DATE", new Gtk.CellRendererText(),"text",3);
		//nxn.get_column(3).set_sort_column_id(3);
		nxn.insert_column_with_attributes(-1, "EMPLOYER", new Gtk.CellRendererText(),"text",4);
		//nxn.get_column(4).set_sort_column_id(4);
		nxn.insert_column_with_attributes(-1, "CITY", new Gtk.CellRendererText(),"text",5);
		//nxn.get_column(5).set_sort_column_id(5);
		nxn.insert_column_with_attributes(-1, "STATE", new Gtk.CellRendererText(),"text",6);
		//nxn.get_column(6).set_sort_column_id(6);
		nxn.insert_column_with_attributes(-1, "PAY FROM", new Gtk.CellRendererText(),"text",7);
		//nxn.get_column(7).set_sort_column_id(7);
		nxn.insert_column_with_attributes(-1, "PAY TO", new Gtk.CellRendererText(),"text",8);
		//nxn.get_column(8).set_sort_column_id(8);
		nxn.insert_column_with_attributes(-1, "PAY UNIT", new Gtk.CellRendererText(),"text",9);
		//nxn.get_column(9).set_sort_column_id(9);

		//nxn.set_model(stor);
		nxn.hexpand = true;
		nxn.vexpand = true;
		contentscroll.set_child(nxn);
		content.append(contentscroll);
		container.append(control);
		container.append(content);
		this.set_child(container);
		doup = true;
	}
}

int main (string[] args) {
	var app = new h1bummer();
	app.activate.connect (() => {
		var win = new qwin(app);
		win.present ();
	});
	return app.run (args);
}