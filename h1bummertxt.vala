using Gtk;

bool doup;
Gtk.TextView nxn;

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

int[] cw;

struct stor {
	string visaclass;
	string jobtitle;
	string soctitle;
	string startdate;
	string employer;
	string city;
	string state;
	int ppy;
}

stor[] dat;
string rend;

// magic numbers based on FY23 H1B data
void loaddat () {
	FileStream stream = FileStream.open ("./source/h1b.csv", "r");
	string line = stream.read_line();
	bool isretardedcsv = false;
	if (line != "") {
		string[] h = line.split(";");
		if (h.length < 74) {
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
					if (cols.length > 73) {
						stor s = stor();
						s.visaclass = cols[5];		cw[0] = int.max(cw[0],cols[5].length);
						s.jobtitle = cols[6];		cw[1] = int.max(cw[0],cols[5].length);
						s.soctitle = cols[8];		cw[2] = int.max(cw[0],cols[5].length);
						s.startdate = cols[10];	cw[3] = int.max(cw[0],cols[5].length);
						s.employer = cols[19];		cw[4] = int.max(cw[0],cols[5].length);
						s.city = cols[23];			cw[5] = int.max(cw[0],cols[5].length);
						s.state = cols[24];		cw[6] = int.max(cw[0],cols[5].length);
						if (cols[73].down().strip() == "hour") {
							s.ppy = (((int.parse(cols[71].replace("$","")) * 8) * 5) * 52);
						} else {
							s.ppy = int.parse(cols[71].replace("$",""));
						}
						dat += s;
					} else { break; }
				}
			} else { break; }
			line = stream.read_line();
			r += 1;
			if (r >= 500000) { print("hit 500K limit.\n"); break; }
		}
	}
}

void renderdat (string[] f, int s) {
	rend = "";
	for (int d = 0; d < dat.length; d++) {
		if (f[0] != "") { if (dat[d].visaclass.contains(f[0]) == false) { break; } }
		if (f[1] != "") { if (dat[d].jobtitle.contains(f[1])) { k = true; } else { break; } }
		if (f[2] != "") { if (dat[d].soctitle.contains(f[2])) { k = true; } else { break; } }
		if (f[3] != "") { if (dat[d].startdate.contains(f[3])) { k = true; } else { break; } }
		if (f[4] != "") { if (dat[d].employer.contains(f[4])) { k = true; } else { break; } }
		if (f[5] != "") { if (dat[d].city.contains(f[5])) { k = true; } else { break; } }
		if (f[6] != "") { if (dat[d].state.contains(f[6])) { k = true; } else { break; } }
		if (int.parse(f[7]) >= dat[d].ppy) { k = true; } else { break; }
		if (k) {
			rend = "%-*s ".printf(cw[0],dat[d].visaclass);
			rend = "%s%-*s ".printf(rend,cw[1],dat[d].jobtitle);
			rend = "%s%-*s ".printf(rend,cw[2],dat[d].soctitle);
			rend = "%s%-*s ".printf(rend,cw[3],dat[d].startdate);
			rend = "%s%-*s ".printf(rend,cw[4],dat[d].employer);
			rend = "%s%-*s ".printf(rend,cw[5],dat[d].city);
			rend = "%s%-*s ".printf(rend,cw[6],dat[d].state);
			rend = "%s%-*d\n".printf(rend,cw[7],dat[d].ppy);
		}
		nxn.buffer.set_text(rend);
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
		Gtk.Entry visaflt = new Gtk.Entry(); 
		Gtk.Entry jobflt = new Gtk.Entry(); 
		Gtk.Entry socflt = new Gtk.Entry(); 
		Gtk.Entry startflt = new Gtk.Entry(); 
		Gtk.Entry employerflt = new Gtk.Entry(); 
		Gtk.Entry cityflt = new Gtk.Entry(); 
		Gtk.Entry stateflt = new Gtk.Entry(); 
		Gtk.Entry payflt = new Gtk.Entry(); 
		control.append(visaflt);
		control.append(jobflt);
		control.append(socflt);
		control.append(startflt);
		control.append(employerflt);
		control.append(cityflt);
		control.append(stateflt);
		control.append(payflt);
		Gtk.Box content = new Gtk.Box(VERTICAL,0);
		content.hexpand = true;
		content.vexpand = true;
		Gtk.ScrolledWindow contentscroll = new Gtk.ScrolledWindow();
		Gtk.TextTagTable nxnbtt = new Gtk.TextTagTable();
		Gtk.TextBuffer nxnb = new Gtk.TextBuffer(nxnbtt);
		nxn = new Gtk.TextView.with_buffer(nxnb);
		nxn.set_monospace(true);
		//nxn.highlight_current_line = true;
		
		cw = new int[8];
		cw[7] = 6;
		loaddat();
		string[] flts = {visaflt.text,jobflt.text,socflt.text,startflt.text,employerflt.text,cityflt.text,stateflt.text,payflt.text};
		renderdat(flts,0);

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