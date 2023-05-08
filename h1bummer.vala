// basic h1b datamining interface
// by cpbrown 2023
//
// todo:
// - hook up the progress bar
// - fix alignment issues in text table
// - fix 'could should not be reached' error on export

using Gtk;

bool doup;
Gtk.TextView nxn;
Gtk.Label fdisplaylabel;
Gtk.ProgressBar fiobar;
string[] flts;
string thisfile;
int snortidx;
Pango.Layout ftlay;
Gtk.Box visabox;
Gtk.Box jobbox;
Gtk.Box socbox;
Gtk.Box startbox;
Gtk.Box employerbox;
Gtk.Box citybox;
Gtk.Box statebox;
Gtk.Box industrybox;
Gtk.Box paybox;

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
// 7 30 industry code (1st 2 digits)
// 8 71 pay from -,
// 8 72 pay to    |- combined into 'pay'
// 8 73 pay unit _'

int[] cw;
string[] dat;
string[,] rend;
string[] idc;
bool testrun;

public void throb () {
	fiobar.pulse();
}

// magic numbers based on FY23 H1B data
public void loaddat (string n) {
	int64 ldts = GLib.get_real_time();
	if (n.strip() != "") {
		dat = {};
		int maxrecords = 900000;
		if (testrun) { maxrecords = 100; }
		cw = {0,0,0,0,0,0,0,0,18};
		nxn.buffer.text = "";
		print("loaddat: loading h1b.csv...\n");
		string np = "./source/%s".printf(n);
		FileStream stream = FileStream.open (np, "r");
		string line = stream.read_line();
		bool isretardedcsv = false;
		if (line != "") {
			string[] cols = line.split(";");
			if (cols.length < 74) {
				string fixl = fixcsvrow(line); 
				cols = fixl.split(";");
				print("loaddat: retarded csv format found...\n");
				isretardedcsv = true;
			}
			for (int g = 0; g < cols.length; g++) {
				print("[%d] %s\n",g,cols[g]);
			}
			int r = 0;
			int pay = 0;
			string pdown = "";
			int ic = 0;
			string icx = "unknown";
			while (line != null) {
				pdown = "";
				ic = 0;
				icx = "unknown";
				pay = 0;
				if (r > maxrecords) { print("loaddat: hit %d row limit.\n",maxrecords); break; }
				if (line.strip() != "") {
					line = line.replace("\t"," ");
					if (r > 0) { 
						if (isretardedcsv) { line = fixcsvrow(line); }
						cols = line.split(";");
					}
					if (cols.length > 73) {
						if (r > 0) {
							pdown = cols[73].down().strip();
							if (pdown.contains("hour")) {
								pay = ((((int.parse(cols[71].replace("$","").replace(",",""))) * 8) * 5) * 52);
							} else {
								if (pdown.contains("bi-weekly")) {
									pay = (int.parse(cols[71].replace("$","").replace(",","")) * 26);
								} else {
									if (pdown.contains("weekly")) {
										pay = (int.parse(cols[71].replace("$","").replace(",","")) * 52);
									} else {
										pay = int.parse(cols[71].replace("$","").replace(",",""));
									}
								}
							}
						} else {
							pay = 0;
						}
						if(cols[30].length > 2) { 
							ic = int.parse(cols[30].substring(0,2));
							if (ic > 0) { icx = idc[ic]; }
						}
						dat += cols[5].down();
						dat += cols[6].down();
						dat += cols[8].down();
						dat += cols[10].down();
						dat += cols[19].down();
						dat += cols[23].down();
						dat += cols[24].down();
						dat += icx;
						dat += "%d".printf(pay);
					} else { break; }
				} else { break; }
				line = stream.read_line();
				r += 1;
			}
		}
		print("loaddat finished.\n");
	} else { print("loaddat aborted, empty filename.\n"); }
	int64 ldte = GLib.get_real_time();
	print("\tload took %f seconds\n",(((double) (ldte - ldts)) / 1000000.0));
}

public void flayout () {
	if (rend.length[0] > 0) { 
		for (int c = 0; c < rend.length[1]; c++) {
			ftlay.set_text(rend[0,c], -1);
			int pw, ph = 0;
			int f = -2;
			ftlay.get_pixel_size(out pw, out ph);
			if (testrun) { print("rend[0,%d] %s pixel width = %d\n",c,rend[0,c],pw); }
			if (c == 0) { visabox.width_request = (pw + f); }
			if (c == 1) { jobbox.width_request = (pw + f); }
			if (c == 2) { socbox.width_request = (pw + f); }
			if (c == 3) { startbox.width_request = (pw + f); }
			if (c == 4) { employerbox.width_request = (pw + f); }
			if (c == 5) { citybox.width_request = (pw + f); }
			if (c == 6) { statebox.width_request = (pw + f); }
			if (c == 7) { industrybox.width_request = (pw + f); }
			if (c == 8) { paybox.width_request = (pw + f); }
		}
		//ftlay.set_text("", -1);
	}
}

public void renderdat () {
	if (flts.length == 9) {
		string rr = "";
		print("rednerdat started (dat.length = %d)...\n",dat.length);
		int[] u = {};
		int x = 0;
		cw = {0,0,0,0,0,0,0,0,18};
		print("renderdat: filter started...\n");
		int64 rfts = GLib.get_real_time();
		for (int d = 0; d < dat.length; d += 9) {
			if (d > 8) {
				if (testrun) { print("dat[%d] = %s\n",d,dat[d]); }
				if (flts[0] != "") { if (dat[d].contains(flts[0]) == false) { continue; } }
				if (flts[1] != "") { if (dat[d+1].contains(flts[1]) == false) { continue; } }
				if (flts[2] != "") { if (dat[d+2].contains(flts[2]) == false) { continue; } }
				if (flts[3] != "") { if (dat[d+3].contains(flts[3]) == false) { continue; } }
				if (flts[4] != "") { if (dat[d+4].contains(flts[4]) == false) { continue; } }
				if (flts[5] != "") { if (dat[d+5].contains(flts[5]) == false) { continue; } }
				if (flts[6] != "") { if (dat[d+6].contains(flts[6]) == false) { continue; } }
				if (flts[7] != "") { if (dat[d+7].contains(flts[7]) == false) { continue; } }
				if (flts[8] != "") { 
					if (int.parse(flts[8]) > int.parse(dat[d+8])) { continue; } 
				}
				u += d;
				cw[0] = int.max(cw[0],dat[d].length);
				cw[1] = int.max(cw[1],dat[d+1].length);
				cw[2] = int.max(cw[2],dat[d+2].length);
				cw[3] = int.max(cw[3],dat[d+3].length);
				cw[4] = int.max(cw[4],dat[d+4].length);
				cw[5] = int.max(cw[5],dat[d+5].length);
				cw[6] = int.max(cw[6],dat[d+6].length);
				cw[7] = int.max(cw[7],dat[d+7].length);
				cw[8] = int.max(cw[8],dat[d+8].length);
			}
			//d += 9;
		}
		int64 rfte = GLib.get_real_time();
		print("\tfiltering took %f seconds\n",(((double) (rfte - rfts)) / 1000000.0));
		int64 rbts = GLib.get_real_time();
		print("renderdat writing to buffer...\n");
		if (u.length > 0) {
			string[,] t = new string[(u.length),9];
			x = 0;
			nxn.buffer.text = "";
			foreach (int y in u) {
				t[x,0] = "%-*s ; ".printf(cw[0],dat[y]);	nxn.buffer.insert_at_cursor(t[x,0],-1);
				t[x,1] = "%-*s ; ".printf(cw[1],dat[y+1]);	nxn.buffer.insert_at_cursor(t[x,1],-1);
				t[x,2] = "%-*s ; ".printf(cw[2],dat[y+2]);	nxn.buffer.insert_at_cursor(t[x,2],-1);
				t[x,3] = "%-*s ; ".printf(cw[3],dat[y+3]);	nxn.buffer.insert_at_cursor(t[x,3],-1);
				t[x,4] = "%-*s ; ".printf(cw[4],dat[y+4]);	nxn.buffer.insert_at_cursor(t[x,4],-1);
				t[x,5] = "%-*s ; ".printf(cw[5],dat[y+5]);	nxn.buffer.insert_at_cursor(t[x,5],-1);
				t[x,6] = "%-*s ; ".printf(cw[6],dat[y+6]);	nxn.buffer.insert_at_cursor(t[x,6],-1);
				t[x,7] = "%-*s ; ".printf(cw[7],dat[y+7]);	nxn.buffer.insert_at_cursor(t[x,7],-1);
				t[x,8] = "%-*s ; ".printf(cw[8],dat[y+8]);	nxn.buffer.insert_at_cursor(t[x,8],-1);
				x += 1;
				nxn.buffer.insert_at_cursor("\n",-1);
			}
			rend = t;
			fdisplaylabel.label = "displaying %d records".printf(rend.length[0]);
			flayout();
		} else { print("renderdat: no data.\n"); nxn.buffer.text = ""; }
		int64 rbte = GLib.get_real_time();
		print("\trender to buffer took %f seconds\n",(((double) (rbte - rbts)) / 1000000.0));
	}
	print("renderdat ended.\n");
}

int comparecol (string[] a, string[] b, int c) {
	//if (testrun) { print("comparing %s with %s... ",a[c],b[c]); }
	//if (testrun) { print(" = %d\n",strcmp(a[c],b[c])); }
	if (c < 8) { return strcmp (a[c], b[c]); }
	if (c == 8) {
		int xx = int.parse(a[8]);
		int yy = int.parse(b[8]);
		if (xx > yy) { return -1; }
		if (xx < yy) { return 1; }
		return 0;
	}
	return 0;
}

public void snorts (int c) {
	int64 snts = GLib.get_real_time();
	print("sorting render data (column %d)...\n",c);
	int n = rend.length[0];
	if (c >= 0 && n > 1) {
		int[] gaps = {701, 301, 132, 57, 23, 10, 4, 1};
		foreach (int g in gaps) {
			for (int i = g; i < n; i++) {
				string[] bb = {rend[i,0],rend[i,1],rend[i,2],rend[i,3],rend[i,4],rend[i,5],rend[i,6],rend[i,7],rend[i,8]};
				int j = i;
				while (j >= g) {
					int k = (j - g);
					string[] aa = {rend[k,0],rend[k,1],rend[k,2],rend[k,3],rend[k,4],rend[k,5],rend[k,6],rend[k,7],rend[k,8]};
					if (comparecol(aa,bb,c) > 0) {
						rend[j,0] = aa[0];
						rend[j,1] = aa[1];
						rend[j,2] = aa[2];
						rend[j,3] = aa[3];
						rend[j,4] = aa[4];
						rend[j,5] = aa[5];
						rend[j,6] = aa[6];
						rend[j,7] = aa[7];
						rend[j,8] = aa[8];
						j -= g;
					} else { break; }
				}
				rend[j,0] = bb[0];
				rend[j,1] = bb[1];
				rend[j,2] = bb[2];
				rend[j,3] = bb[3];
				rend[j,4] = bb[4];
				rend[j,5] = bb[5];
				rend[j,6] = bb[6];
				rend[j,7] = bb[7];
				rend[j,8] = bb[8];
			}
			if (testrun) {
				print("gap %d sort:\n",g);
				for (int r = 0; r < rend.length[0]; r++) {
					print("\trend[%d,%d] = %s\n",r,c,rend[r,c]);
				}
			}
		}
		nxn.buffer.text = "";
		print("writing sorted output to buffer...\n");
		for (int r = 0; r < rend.length[0]; r ++) {
			nxn.buffer.insert_at_cursor(rend[r,0], -1);
			nxn.buffer.insert_at_cursor(rend[r,1], -1);
			nxn.buffer.insert_at_cursor(rend[r,2], -1);
			nxn.buffer.insert_at_cursor(rend[r,3], -1);
			nxn.buffer.insert_at_cursor(rend[r,4], -1);
			nxn.buffer.insert_at_cursor(rend[r,5], -1);
			nxn.buffer.insert_at_cursor(rend[r,6], -1);
			nxn.buffer.insert_at_cursor(rend[r,7], -1);
			nxn.buffer.insert_at_cursor(rend[r,8], -1);
			nxn.buffer.insert_at_cursor("\n",-1);
		}
	} else { print("no need to sort.\n"); }
	flayout();
	int64 snte = GLib.get_real_time();
	print("\tsort took %f seconds\n",(((double) (snte - snts)) / 1000000.0));
}


string[] buildidcs () {
	string[] o = new string[93];
	for (int i = 0; i < 93; i++) {
		o[i] = "unknown";
		if (i > 10 && i <= 11) { o[i] = "primary extraction: living"; }
		if (i > 20 && i <= 21) { o[i] = "primary extraction: dead"; }
		if (i > 21 && i <= 22) { o[i] = "utilities"; }
		if (i > 22 && i <= 23) { o[i] = "construction"; }
		if (i > 30 && i <= 33) { o[i] = "manufacturing"; }
		if (i > 41 && i <= 42) { o[i] = "wholesale"; }
		if (i > 43 && i <= 45) { o[i] = "retail"; }
		if (i > 47 && i <= 49) { o[i] = "logistics"; }
		if (i > 49 && i <= 51) { o[i] = "information"; }
		if (i > 51 && i <= 52) { o[i] = "finance and insurance"; }
		if (i > 52 && i <= 53) { o[i] = "real estate and leasing"; }
		if (i > 53 && i <= 54) { o[i] = "professional, scientific & technical services"; }
		if (i > 54 && i <= 55) { o[i] = "management"; }
		if (i > 55 && i <= 56) { o[i] = "admin, waste & remedial services"; }
		if (i > 60 && i <= 61) { o[i] = "education"; }
		if (i > 61 && i <= 62) { o[i] = "healthcare and social services"; }
		if (i > 70 && i <= 71) { o[i] = "arts, entertainment and recreation"; }
		if (i > 71 && i <= 72) { o[i] = "hospitality"; }
		if (i > 80 && i <= 81) { o[i] = "other services"; }
		if (i > 91 && i <= 92) { o[i] = "government"; }
	}
	return o;
}

public class h1bummer : Gtk.Application {
	construct {
		application_id = "com.h1bummer.h1bummer";
		flags = ApplicationFlags.FLAGS_NONE;
	}
}

// the window

public class qwin : Gtk.ApplicationWindow {
	private Gtk.Entry visaflt;
	private Gtk.Entry jobflt;
	private Gtk.Entry socflt;
	private Gtk.Entry startflt;
	private Gtk.Entry employerflt;
	private Gtk.Entry cityflt;
	private Gtk.Entry stateflt;
	private Gtk.Entry industryflt;
	private Gtk.Entry payflt;
	private void getflts () {
		flts = {
			visaflt.text.down(),
			jobflt.text.down(),
			socflt.text.down(),
			startflt.text.down(),
			employerflt.text.down(),
			cityflt.text.down(),
			stateflt.text.down(),
			industryflt.text.down(),
			payflt.text.down()
		};
	}
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
		this.set_default_size(1280, (720 - 46));
		Gtk.Box container = new Gtk.Box(VERTICAL,0);
		Gtk.Box control = new Gtk.Box(HORIZONTAL,0);
		//Gtk.ScrolledWindow controlscroll = new Gtk.ScrolledWindow();
		//controlscroll.height_request = 100;
		Gtk.Box fileio = new Gtk.Box(HORIZONTAL,10);
		Gtk.Label fiolabel = new Gtk.Label("no file");
		fdisplaylabel = new Gtk.Label("no display");
		//Gtk.Button fiobutton = new Gtk.Button();
		Gtk.Entry fiotemp = new Gtk.Entry();
		ftlay = fiotemp.create_pango_layout(null);
		//headingnamelayout.set_text(headings[hh].name, -1);
		//headingnamelayout.get_pixel_size(out pw, out ph);
		//fiobutton.icon_name = "view-refresh";
		fiobar = new Gtk.ProgressBar();
		fiobar.valign = Align.CENTER;
		fileio.append(fiolabel);
		//fileio.append(fiobutton);
		fileio.append(fiobar);
		fileio.append(fiotemp);
		fileio.append(fdisplaylabel);

		visabox = new Gtk.Box(VERTICAL,0);
		jobbox = new Gtk.Box(VERTICAL,0);
		socbox = new Gtk.Box(VERTICAL,0);
		startbox = new Gtk.Box(VERTICAL,0);
		employerbox = new Gtk.Box(VERTICAL,0);
		citybox = new Gtk.Box(VERTICAL,0);
		statebox = new Gtk.Box(VERTICAL,0);
		industrybox = new Gtk.Box(VERTICAL,0);
		paybox = new Gtk.Box(VERTICAL,0);

		Gtk.Button visasort = new Gtk.Button.with_label("v");
		Gtk.Button jobsort = new Gtk.Button.with_label("job");
		Gtk.Button socsort = new Gtk.Button.with_label("occupation");
		Gtk.Button startsort = new Gtk.Button.with_label("date");
		Gtk.Button employersort = new Gtk.Button.with_label("employer");
		Gtk.Button citysort = new Gtk.Button.with_label("city");
		Gtk.Button statesort = new Gtk.Button.with_label("state");
		Gtk.Button industrysort = new Gtk.Button.with_label("industry");
		Gtk.Button paysort = new Gtk.Button.with_label("pay");
		//paysort.hexpand = true;

		visaflt = new Gtk.Entry(); 
		jobflt = new Gtk.Entry(); 
		socflt = new Gtk.Entry(); 
		startflt = new Gtk.Entry(); 
		employerflt = new Gtk.Entry(); 
		cityflt = new Gtk.Entry(); 
		stateflt = new Gtk.Entry(); 
		industryflt = new Gtk.Entry(); 
		payflt = new Gtk.Entry();
		stateflt.set_text("ca");
		socflt.set_text("artist");
		//payflt.hexpand = true;

		visaflt.width_request = 10; visaflt.hexpand = false;
		jobflt.width_request = 10; jobflt.hexpand = false;
		socflt.width_request = 10; socflt.hexpand = false;
		startflt.width_request = 10; startflt.hexpand = false;
		employerflt.width_request = 10; employerflt.hexpand = false;
		cityflt.width_request = 10; cityflt.hexpand = false;
		stateflt.width_request = 10; stateflt.hexpand = false;
		industryflt.width_request = 10; industryflt.hexpand = false;
		payflt.width_request = 10; payflt.hexpand = false;

		visasort.width_request = 10; visasort.hexpand = false;
		jobsort.width_request = 10; jobsort.hexpand = false;
		socsort.width_request = 10; socsort.hexpand = false;
		startsort.width_request = 10; startsort.hexpand = false;
		employersort.width_request = 10; employersort.hexpand = false;
		citysort.width_request = 10; citysort.hexpand = false;
		statesort.width_request = 10; statesort.hexpand = false;
		industrysort.width_request = 10; industrysort.hexpand = false;
		paysort.width_request = 10; paysort.hexpand = false;

		visabox.append(visasort);
		visabox.get_first_child().margin_start = 0;
		visabox.get_first_child().margin_end = 0;
		visabox.append(visaflt);
		jobbox.append(jobsort);
		jobbox.append(jobflt);
		socbox.append(socsort);
		socbox.append(socflt);
		startbox.append(startsort);
		startbox.append(startflt);
		employerbox.append(employersort);
		employerbox.append(employerflt);
		citybox.append(citysort);
		citybox.append(cityflt);
		statebox.append(statesort);
		statebox.append(stateflt);
		industrybox.append(industrysort);
		industrybox.append(industryflt);
		paybox.append(paysort);
		paybox.append(payflt);

		visabox.hexpand = false;
		jobbox.hexpand = false;
		socbox.hexpand = false;
		startbox.hexpand = false;
		employerbox.hexpand = false;
		citybox.hexpand = false;
		statebox.hexpand = false;
		industrybox.hexpand = false;
		paybox.hexpand = true;

		visabox.set_halign(START);
		jobbox.set_halign(START);
		socbox.set_halign(START);
		startbox.set_halign(START);
		employerbox.set_halign(START);
		citybox.set_halign(START);
		statebox.set_halign(START);
		industrybox.set_halign(START);
		paybox.set_halign(FILL);

		control.append(visabox);
		control.append(jobbox);
		control.append(socbox);
		control.append(startbox);
		control.append(employerbox);
		control.append(citybox);
		control.append(statebox);
		control.append(industrybox);
		control.append(paybox);

// todo:
// fix widths of header boxes, vary width of trailing expander box...
		control.hexpand = true;

		Gtk.Box content = new Gtk.Box(VERTICAL,0);
		content.hexpand = true;
		content.vexpand = true;
		Gtk.ScrolledWindow contentscroll = new Gtk.ScrolledWindow();
		Gtk.Box contentscrollbox = new Gtk.Box(VERTICAL,0);
		Gtk.TextTagTable nxnbtt = new Gtk.TextTagTable();
		Gtk.TextBuffer nxnb = new Gtk.TextBuffer(nxnbtt);
		nxn = new Gtk.TextView.with_buffer(nxnb);
		nxn.set_monospace(true);
		contentscrollbox.append(control);
		contentscrollbox.append(nxn);
		contentscroll.set_child(contentscrollbox);
		//nxn.highlight_current_line = true;

		snortidx = -1;

		//fiobutton.clicked.connect(() => {
		//	getflts();
		//	renderdat();
		//	snorts(snortidx);
		//});

		cw = new int[9];
		cw[7] = 6;
		getflts();
		idc = buildidcs();


		string sbbkg = "#112633";	// sb blue
		string sbsel = "#50B5F2";	// selection/text
		string sblin = "#08131A";	// dark lines
		string sbhil = "#1D4259";	// sbbkg + 10
		string sblit = "#19394D";	// sbbkg + 5
		string sbmrk = "#153040";  // sbbkg + 2
		string sbfld = "#132C3B";	// sbbkg - 2
		string sblow = "#153040";	// sbbkg - 5
		string sbshd = "#0C1D26";	// sbbkg - 10
		string sbent = "#0E232E";	// sbbkg - 12

		Gtk.CssProvider popcsp = new Gtk.CssProvider();
		string popcss = ".xx { border-radius: 0; border-color: %s; background: %s; color: %s; }".printf(sblin,sbbkg,sbsel);
		popcsp.load_from_data(popcss.data);

		Gtk.CssProvider butcsp = new Gtk.CssProvider();
		string butcss = ".xx { border-radius: 0; border-top: 1px solid %s; border-left: 1px solid %s; border-right: 1px solid %s; border-bottom: 1px solid %s; background: %s; color: %s; font-size: 12px; padding: 0px; font-family: monospace; }".printf(sbhil,sbhil,sbshd,sbshd,sblit,sbsel);
		butcsp.load_from_data(butcss.data);

		Gtk.CssProvider btncsp = new Gtk.CssProvider();
		string btncss = ".xx { border-radius: 0; border-top: 1px solid %s; border-left: 1px solid %s; border-right: 1px solid %s; border-bottom: 1px solid %s; background: %s; color: %s; }".printf(sbhil,sbhil,sbshd,sbshd,sblit,sbsel);
		btncsp.load_from_data(btncss.data);

		Gtk.CssProvider entcsp = new Gtk.CssProvider();
		string entcss = ".xx { border-radius: 0; border-top: 1px solid %s; border-left: 1px solid %s; border-right: 1px solid %s; border-bottom: 1px solid %s; background: %s; color: %s; font-size: 12px; padding: 0px; padding-left: 5px; font-family: monospace; }".printf(sblit,sblit,sbshd,sbshd,sbmrk,sbsel);
		entcsp.load_from_data(entcss.data);

		Gtk.CssProvider fldcsp = new Gtk.CssProvider();
		string fldcss = ".xx { border-color: %s; background: %s; color: %s;  }".printf(sblin,sbmrk,sbsel);
		fldcsp.load_from_data(fldcss.data);

		Gtk.CssProvider lblcsp = new Gtk.CssProvider();
		string lblcss = ".xx { font-size: 30px; color: %s; }".printf(sbhil);
		lblcsp.load_from_data(lblcss.data);

		Gtk.CssProvider glbcsp = new Gtk.CssProvider();
		string glbcss = ".xx { color: %s; }".printf(sbsel);
		glbcsp.load_from_data(glbcss.data);

		Gtk.CssProvider nxncsp = new Gtk.CssProvider();
		string nxncss = ".xx { background: %s; font-size: 12px; color: %s; font-family: monospace; }".printf(sbbkg,sbsel);
		nxncsp.load_from_data(nxncss.data);

		Gtk.CssProvider boxcsp = new Gtk.CssProvider();
		string boxcss = ".xx { background: %s; }".printf(sbbkg);
		boxcsp.load_from_data(boxcss.data);

		Gtk.CssProvider knbcsp = new Gtk.CssProvider();
		string knbcss = ".xx { background: %s; }".printf(sblit);
		knbcsp.load_from_data(knbcss.data);

		Gtk.CssProvider iobcsp = new Gtk.CssProvider();
		string iobcss = ".xx { border-radius: 0; border-color: %s; background: %s; color: %s; }".printf(sblin,sblow,sbsel);
		iobcsp.load_from_data(iobcss.data);

		visaflt.get_style_context().add_provider(entcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		visaflt.get_style_context().add_class("xx");
		jobflt.get_style_context().add_provider(entcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		jobflt.get_style_context().add_class("xx");
		socflt.get_style_context().add_provider(entcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		socflt.get_style_context().add_class("xx");
		startflt.get_style_context().add_provider(entcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		startflt.get_style_context().add_class("xx");
		employerflt.get_style_context().add_provider(entcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		employerflt.get_style_context().add_class("xx");
		cityflt.get_style_context().add_provider(entcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		cityflt.get_style_context().add_class("xx");
		stateflt.get_style_context().add_provider(entcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		stateflt.get_style_context().add_class("xx");
		industryflt.get_style_context().add_provider(entcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		industryflt.get_style_context().add_class("xx");
		payflt.get_style_context().add_provider(entcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		payflt.get_style_context().add_class("xx");
		nxn.get_style_context().add_provider(nxncsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		nxn.get_style_context().add_class("xx");
		fiotemp.get_style_context().add_provider(nxncsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		fiotemp.get_style_context().add_class("xx");
		fileio.get_style_context().add_provider(boxcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		fileio.get_style_context().add_class("xx");
		control.get_style_context().add_provider(boxcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		control.get_style_context().add_class("xx");
		content.get_style_context().add_provider(boxcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		content.get_style_context().add_class("xx");
		//fiobutton.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		//fiobutton.get_style_context().add_class("xx");
		fiolabel.get_style_context().add_provider(lblcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		fiolabel.get_style_context().add_class("xx");
		fdisplaylabel.get_style_context().add_provider(lblcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		fdisplaylabel.get_style_context().add_class("xx");
		visasort.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		visasort.get_style_context().add_class("xx");
		jobsort.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		jobsort.get_style_context().add_class("xx");
		socsort.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		socsort.get_style_context().add_class("xx");
		startsort.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		startsort.get_style_context().add_class("xx");
		employersort.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		employersort.get_style_context().add_class("xx");
		citysort.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		citysort.get_style_context().add_class("xx");
		statesort.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		statesort.get_style_context().add_class("xx");
		industrysort.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		industrysort.get_style_context().add_class("xx");
		paysort.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		paysort.get_style_context().add_class("xx");

		iobar.get_style_context().add_provider(iobcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		iobar.get_style_context().add_class("xx");

		Gtk.MenuButton savemenu = new Gtk.MenuButton();
		Gtk.MenuButton loadmenu = new Gtk.MenuButton();
		savemenu.icon_name = "document-save-symbolic";
		loadmenu.icon_name = "document-open-symbolic";

		savemenu.get_first_child().get_style_context().add_provider(btncsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		savemenu.get_first_child().get_style_context().add_class("xx");
		loadmenu.get_first_child().get_style_context().add_provider(btncsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		loadmenu.get_first_child().get_style_context().add_class("xx");

		Gtk.GestureClick loadmenuclick = new Gtk.GestureClick();
		loadmenu.add_controller(loadmenuclick);


		Gtk.Button savebutton = new Gtk.Button.with_label("save");
		savebutton.get_style_context().add_provider(btncsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		savebutton.get_style_context().add_class("xx");
		Gtk.Popover savepop = new Gtk.Popover();
		Gtk.Popover loadpop = new Gtk.Popover();
		Gtk.Box savepopbox = new Gtk.Box(VERTICAL,0);
		Gtk.Box loadpopbox = new Gtk.Box(VERTICAL,0);
		savepopbox.margin_end = 2;
		savepopbox.margin_top = 2;
		savepopbox.margin_start = 2;
		savepopbox.margin_bottom = 2;
		loadpopbox.margin_end = 2;
		loadpopbox.margin_top = 2;
		loadpopbox.margin_start = 2;
		loadpopbox.margin_bottom = 2;
		Gtk.Entry saveentry = new Gtk.Entry();
		saveentry.get_style_context().add_provider(fldcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		saveentry.get_style_context().add_class("xx");
		saveentry.text = "export";
		savepopbox.append(saveentry);
		savepopbox.append(savebutton);
		savepop.set_child(savepopbox);
		loadpop.set_child(loadpopbox);
		savemenu.popover = savepop;
		loadmenu.popover = loadpop;
		iobar.pack_start(loadmenu);
		iobar.pack_end(savemenu);

		savepop.get_first_child().get_style_context().add_provider(boxcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		savepop.get_first_child().get_style_context().add_class("xx");
		loadpop.get_first_child().get_style_context().add_provider(boxcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		loadpop.get_first_child().get_style_context().add_class("xx");

//events
		savebutton.clicked.connect(() => {
			if (saveentry.text.strip() != "" && nxn.buffer.text.length > 0) {
				bool allgood = true;
				string pth = GLib.Environment.get_current_dir();
				pth = pth.concat("/export/");
				GLib.Dir dcr = null;
				print("check dir: %s\n",pth);
				try { dcr = Dir.open (pth, 0); } catch (Error e) { print("checkdir failed: %s\n",e.message); allgood = false; }
				File hfile = File.new_for_path(pth.concat(saveentry.text.strip(),".csv"));
				File hdir = File.new_for_path(pth);
				if (allgood == false) {
					print("make dir...\n");
					try { 
						hdir.make_directory_with_parents();
						print("made export dir: %s\n",pth);
						allgood = true;
					} catch (Error e) { print("makedirs failed: %s\n",e.message); allgood = false; }
				}
				if (allgood) {
					print("exporting...\n");
					FileOutputStream hose = hfile.replace(null,false,FileCreateFlags.PRIVATE);
					try {
						string headers = "";
						string[] hh = {"visa class","job title","SOC title","start date","employer","city","state","industry","pay p/a"};
						for (int h = 0; h < 9; h++) {
							headers = "%s%-*s ; ".printf(headers,cw[h],hh[h]);
						}
						headers = headers.concat("\n");
						print("\twriting headers: %s\n",headers);
						hose.write(headers.data);
						hose.write(nxn.buffer.text.data);
						print("exported.\n\t%s\n",hfile.get_path());
					} catch (Error e) { print("write failed: %s\n",e.message); }
				} else { print("couldn't make dir, aborting export.\n"); }
			} else { print("empty name or data, aborting export."); }
			savepop.popdown();
		});
		visaflt.activate.connect(() => {getflts(); renderdat(); snorts(snortidx); });
		visasort.clicked.connect(() => {getflts(); snortidx = 0; renderdat(); snorts(snortidx); });
		jobflt.activate.connect(() => {getflts();  renderdat(); snorts(snortidx); });
		jobsort.clicked.connect(() => {getflts(); snortidx = 1; renderdat(); snorts(snortidx); });
		socflt.activate.connect(() => {getflts(); renderdat(); snorts(snortidx); });
		socsort.clicked.connect(() => {getflts(); snortidx = 2; renderdat(); snorts(snortidx); });
		startflt.activate.connect(() => {getflts(); renderdat(); snorts(snortidx); });
		startsort.clicked.connect(() => {getflts(); snortidx = 3; renderdat(); snorts(snortidx); });
		employerflt.activate.connect(() => {getflts(); renderdat(); snorts(snortidx); });
		employersort.clicked.connect(() => {getflts(); snortidx = 4; renderdat(); snorts(snortidx); });
		cityflt.activate.connect(() => {getflts(); renderdat(); snorts(snortidx); });
		citysort.clicked.connect(() => {getflts(); snortidx = 5; renderdat(); snorts(snortidx); });
		stateflt.activate.connect(() => {getflts(); renderdat(); snorts(snortidx); });
		statesort.clicked.connect(() => {getflts(); snortidx = 6; renderdat(); snorts(snortidx); });
		industryflt.activate.connect(() => {getflts(); renderdat(); snorts(snortidx); });
		industrysort.clicked.connect(() => {getflts(); snortidx = 7; snorts(snortidx); });
		payflt.activate.connect(() => {getflts(); renderdat(); snorts(snortidx); });
		paysort.clicked.connect(() => {getflts(); snortidx = 8; snorts(snortidx); });
// load

		loadmenuclick.pressed.connect(() => {
			if (doup) {
				doup = false;
				testrun = false;
				while (loadpopbox.get_first_child() != null) {
					loadpopbox.remove(loadpopbox.get_first_child());
				}
				print("LOAD: button pressed...\n");
				var pth = GLib.Environment.get_current_dir();
				pth = pth.concat("/source/");
				bool allgood = true;
				GLib.Dir dcr = null;
				try { dcr = Dir.open (pth, 0); } catch (Error e) { print("%s\n",e.message); allgood = false; }
				if (allgood) {
					string? name = null;
					print("LOAD: searching for csv files in %s\n",((string) pth));
					while ((name = dcr.read_name ()) != null) {
						var exts = name.split(".");
						if (exts.length == 2) {
							print("LOAD:\tchecking file: %s\n", name);
							if (exts[1] == "csv") {
								Gtk.Button muh = new Gtk.Button.with_label (name);
								muh.get_style_context().add_provider(btncsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
								muh.get_style_context().add_class("xx");
								loadpopbox.append(muh);
/*
								muh.clicked.connect ((buh) => {
									if (buh.label.strip() != "") {
										print("LOAD:\t\tloading %s...\n",buh.label);
										yield loaddat(buh.label.strip());
										fiolabel.label = "csv %s has %d records".printf(buh.label,dat.length);
										saveentry.set_text("%s_export".printf(buh.label.split(".")[0]));
									} else { print("LOAD: nothing to load, aborting.\n"); }
									loadpop.popdown();
								});
*/
								muh.clicked.connect ((buh) => { 
									saveentry.set_text("%s_export".printf(buh.label.split(".")[0]));
									thisfile = buh.label.strip();
									fiolabel.label = "loading...";
									getflts();
									Idle.add(() => {
										loaddat(buh.label);
										fiolabel.label = "loaded %d records".printf(((dat.length - 9) / 9));
										renderdat();
										print("load completed.\n");
										return false;
									});
									loadpop.popdown();
								});
							}
						}
					}
					Gtk.Box tstbox = new Gtk.Box(HORIZONTAL,5);
					Gtk.Label tstlabel = new Gtk.Label("testrun");
					Gtk.Switch tst = new Gtk.Switch();
					tst.get_last_child().get_style_context().add_provider(knbcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
					tst.get_last_child().get_style_context().add_class("xx");
					tstlabel.get_style_context().add_provider(glbcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
					tstlabel.get_style_context().add_class("xx");
					tst.notify["active"].connect_after(() => {
						testrun = tst.active;
					});
					tstbox.append(tstlabel);
					tstbox.append(tst);
					loadpopbox.append(tstbox);
				}
				doup = true;
			}			
		});

		nxn.hexpand = false;
		nxn.vexpand = false;
		contentscrollbox.vexpand = true;
		contentscroll.set_child(contentscrollbox);
		//content.append(control);
		content.append(contentscroll);
		container.append(fileio);
		//container.append(controlscroll);
		container.append(content);
		this.set_child(container);
		doup = true;

		//this.notify.connect(() => {
		//	print("visabox.width_request = %d\n",visabox.width_request);
		//});
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