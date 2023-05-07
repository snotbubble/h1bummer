// basic h1b datamining interface
// by cpbrown 2023
//
// todo:
// - compare struct[] vs string[,], mem & time
// - load direct from xlsx
// - fix ui alignment issues
// - fix sort
// - disable ui if no data
// - thread load properly so it doesn't block the main loop
// - given the above, hook-up the progressbar
// - export textbuffer to csv via save popup

using Gtk;

bool doup;
Gtk.TextView nxn;
Gtk.ProgressBar fiobar;
string[] flts;
string thisfile;
int snortidx;

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
string[,] rend;
bool testrun;

public async void throb () {
	fiobar.pulse();
	yield;
}

// magic numbers based on FY23 H1B data
public async void loaddat (string n) {
	if (n.strip() != "") {
		int maxrecords = 900000;
		if (testrun) { maxrecords = 100; }
		dat = {};
		cw = {0,0,0,0,0,0,0,6};
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
			while (line != null) {
				pdown = "";
				pay = 0;
				if (r > maxrecords) { print("loaddat: hit %d row limit.\n",maxrecords); break; }
				if (line.strip() != "") {
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
						stor s = stor();
						s.visaclass = cols[5].down();
						s.jobtitle = cols[6].down();
						s.soctitle = cols[8].down();
						s.startdate = cols[10].down();
						s.employer = cols[19].down();
						s.city = cols[23].down();
						s.state = cols[24].down();
						if (testrun) { print("[%d] cols[71] = %s\n",r,cols[71]); }
						s.ppy = pay;
						dat += s;
					} else { break; }
				} else { break; }
				line = stream.read_line();
				r += 1;
			}
		}
		print("loaddat: header col 0 is %s\n",dat[0].visaclass);
		print("loaddat finished.\n");
	} else { print("loaddat aborted, empty filename.\n"); }
	yield;
}

public async void renderdat () {
	if (flts.length == 8) {
		string rr = "";
		print("rednerdat started (dat.length = %d)...\n",dat.length);
		int[] u = {};
		cw = {0,0,0,0,0,0,0,6};
		print("renderdat: filter started...\n");
		for (int d = 0; d < dat.length; d++) {
			if (d > 0) {
				if (flts[0] != "") { if (dat[d].visaclass.contains(flts[0]) == false) { continue; } }
				if (flts[1] != "") { if (dat[d].jobtitle.contains(flts[1]) == false) { continue; } }
				if (flts[2] != "") { if (dat[d].soctitle.contains(flts[2]) == false) { continue; } }
				if (flts[3] != "") { if (dat[d].startdate.contains(flts[3]) == false) { continue; } }
				if (flts[4] != "") { if (dat[d].employer.contains(flts[4]) == false) { continue; } }
				if (flts[5] != "") { if (dat[d].city.contains(flts[5]) == false) { continue; } }
				//if (testrun) { print("[%d] %s contains %s ?\n",d,dat[d].state,flts[6]); }
				if (flts[6] != "") { if (dat[d].state.contains(flts[6]) == false) { continue; } }
				//if (testrun) { print("[%d] %d > %d ?\n",d,int.parse(flts[7]),dat[d].ppy); }
				if (flts[7] != "") { 
					if (int.parse(flts[7]) > dat[d].ppy) {
						continue;
					} 
				}
				u += d;
			}
			cw[0] = int.max(cw[0],dat[d].visaclass.length);
			cw[1] = int.max(cw[1],dat[d].jobtitle.length);
			cw[2] = int.max(cw[2],dat[d].soctitle.length);
			cw[3] = int.max(cw[3],dat[d].startdate.length);
			cw[4] = int.max(cw[4],dat[d].employer.length);
			cw[5] = int.max(cw[5],dat[d].city.length);
			cw[6] = int.max(cw[6],dat[d].state.length);
		}
		print("renderdat: initializing output...\n");
		string[,] t = new string[(u.length),8];
		int x = 0;
		foreach (int d in u) {
			t[x,0] = "%-*s".printf(cw[0],dat[d].visaclass);
			t[x,1] = "%-*s".printf(cw[1],dat[d].jobtitle);
			t[x,2] = "%-*s".printf(cw[2],dat[d].soctitle);
			t[x,3] = "%-*s".printf(cw[3],dat[d].startdate);
			t[x,4] = "%-*s".printf(cw[4],dat[d].employer);
			t[x,5] = "%-*s".printf(cw[5],dat[d].city);
			t[x,6] = "%-*s".printf(cw[6],dat[d].state);
			t[x,7] = "%d".printf(dat[d].ppy);
			x += 1;
		}
		print("renderdat writing to buffer...\n");
		for (int r = 0; r < t.length[0]; r++) {
			for (int c = 0; c < t.length[1]; c++) {
				rr = "%s%s;".printf(rr,t[r,c]);
			}
			rr._chomp();
			rr = "%s\n".printf(rr);
		}
		nxn.buffer.text = rr;
		rend = t;
	}
	print("renderdat ended.\n");
	yield;
}

int comparecol (string[] a, string[] b, int c) {
	if (c < 7) { return strcmp (a[c], b[c]); }
	if (c == 7) {
		int xx = int.parse(a[7]);
		int yy = int.parse(b[7]);
		if (xx > yy) { return -1; }
		if (xx < yy) { return 1; }
		return 0;
	}
	return 0;
}

public async void snorts (int c) {
	int n = rend.length[0];
	if (c >= 0 && n > 1) {
		int[] gaps = {701, 301, 132, 57, 23, 10, 4, 1};
		foreach (int g in gaps) {
			for (int i = 0; i < n; i++) {
				string[] bb = {rend[i,0],rend[i,1],rend[i,2],rend[i,3],rend[i,4],rend[i,5],rend[i,6],rend[i,7]};
				int j = i;
				while (j >= g) {
					int k = (j - g);
					string[] aa = {rend[k,0],rend[k,1],rend[k,2],rend[k,3],rend[k,4],rend[k,5],rend[k,6],rend[k,7]};
					if (comparecol(aa,bb,c) > 0) {
						rend[j,0] = aa[0];
						rend[j,1] = aa[1];
						rend[j,2] = aa[2];
						rend[j,3] = aa[3];
						rend[j,4] = aa[4];
						rend[j,5] = aa[5];
						rend[j,6] = aa[6];
						rend[j,7] = aa[7];
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
			}
		}
	}
}


public async void loadit (string l) {
	if (l.strip() != "") {
		print("LOAD:\t\tloading %s...\n",l);
		//yield loaddat(l.strip());
		yield loaddat(l.strip());
	} else { print("LOAD: nothing to load, aborting.\n"); }
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
		this.set_default_size(720, (720 - 46));
		Gtk.Box container = new Gtk.Box(VERTICAL,0);
		Gtk.Box control = new Gtk.Box(HORIZONTAL,0);
		Gtk.Box fileio = new Gtk.Box(HORIZONTAL,10);
		Gtk.Label fiolabel = new Gtk.Label("file");
		Gtk.Button fiobutton = new Gtk.Button();
		fiobutton.icon_name = "view-refresh";
		fiobar = new Gtk.ProgressBar();
		fiobar.valign = Align.CENTER;
		fileio.append(fiolabel);
		fileio.append(fiobutton);
		fileio.append(fiobar);

		Gtk.Box visabox = new Gtk.Box(VERTICAL,0);
		Gtk.Box jobbox = new Gtk.Box(VERTICAL,0);
		Gtk.Box socbox = new Gtk.Box(VERTICAL,0);
		Gtk.Box startbox = new Gtk.Box(VERTICAL,0);
		Gtk.Box employerbox = new Gtk.Box(VERTICAL,0);
		Gtk.Box citybox = new Gtk.Box(VERTICAL,0);
		Gtk.Box statebox = new Gtk.Box(VERTICAL,0);
		Gtk.Box paybox = new Gtk.Box(VERTICAL,0);

		Gtk.Button visasort = new Gtk.Button.with_label("visa");
		Gtk.Button jobsort = new Gtk.Button.with_label("job");
		Gtk.Button socsort = new Gtk.Button.with_label("occupation");
		Gtk.Button startsort = new Gtk.Button.with_label("date");
		Gtk.Button employersort = new Gtk.Button.with_label("employer");
		Gtk.Button citysort = new Gtk.Button.with_label("city");
		Gtk.Button statesort = new Gtk.Button.with_label("state");
		Gtk.Button paysort = new Gtk.Button.with_label("pay");

		visaflt = new Gtk.Entry(); 
		jobflt = new Gtk.Entry(); 
		socflt = new Gtk.Entry(); 
		startflt = new Gtk.Entry(); 
		employerflt = new Gtk.Entry(); 
		cityflt = new Gtk.Entry(); 
		stateflt = new Gtk.Entry(); 
		payflt = new Gtk.Entry();
		stateflt.set_text("ca");
		socflt.set_text("artist");

		visabox.append(visasort);
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
		paybox.append(paysort);
		paybox.append(payflt);

		control.append(visabox);
		control.append(jobbox);
		control.append(socbox);
		control.append(startbox);
		control.append(employerbox);
		control.append(citybox);
		control.append(statebox);
		control.append(paybox);

		Gtk.Box content = new Gtk.Box(VERTICAL,0);
		content.hexpand = true;
		content.vexpand = true;
		Gtk.ScrolledWindow contentscroll = new Gtk.ScrolledWindow();
		Gtk.TextTagTable nxnbtt = new Gtk.TextTagTable();
		Gtk.TextBuffer nxnb = new Gtk.TextBuffer(nxnbtt);
		nxn = new Gtk.TextView.with_buffer(nxnb);
		nxn.set_monospace(true);
		//nxn.highlight_current_line = true;

		snortidx = -1;

		fiobutton.clicked.connect(() => {
			getflts();
			snorts(snortidx);
			renderdat();
		});

		cw = new int[8];
		cw[7] = 6;
		flts = {visaflt.text,jobflt.text,socflt.text,startflt.text,employerflt.text,cityflt.text,stateflt.text,payflt.text};


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
		string butcss = ".xx { border-radius: 0; border-top: 1px solid %s; border-left: 1px solid %s; border-right: 1px solid %s; border-bottom: 1px solid %s; background: %s; color: %s; }".printf(sbhil,sbhil,sbshd,sbshd,sblit,sbsel);
		butcsp.load_from_data(butcss.data);

		Gtk.CssProvider entcsp = new Gtk.CssProvider();
		string entcss = ".xx { border-radius: 0; border-top: 1px solid %s; border-left: 1px solid %s; border-right: 1px solid %s; border-bottom: 1px solid %s; background: %s; color: %s; }".printf(sblit,sblit,sbshd,sbshd,sbmrk,sbsel);
		entcsp.load_from_data(entcss.data);

		Gtk.CssProvider lblcsp = new Gtk.CssProvider();
		string lblcss = ".xx { font-size: 30px; color: %s; }".printf(sbhil);
		lblcsp.load_from_data(lblcss.data);

		Gtk.CssProvider nxncsp = new Gtk.CssProvider();
		string nxncss = ".xx { background: %s; font-size: 12px; color: %s; }".printf(sbbkg,sbsel);
		nxncsp.load_from_data(nxncss.data);

		Gtk.CssProvider boxcsp = new Gtk.CssProvider();
		string boxcss = ".xx { background: %s; }".printf(sbbkg);
		boxcsp.load_from_data(boxcss.data);

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
		payflt.get_style_context().add_provider(entcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		payflt.get_style_context().add_class("xx");
		nxn.get_style_context().add_provider(nxncsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		nxn.get_style_context().add_class("xx");
		fileio.get_style_context().add_provider(boxcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		fileio.get_style_context().add_class("xx");
		control.get_style_context().add_provider(boxcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		control.get_style_context().add_class("xx");
		content.get_style_context().add_provider(boxcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		content.get_style_context().add_class("xx");
		fiobutton.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		fiobutton.get_style_context().add_class("xx");
		fiolabel.get_style_context().add_provider(lblcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		fiolabel.get_style_context().add_class("xx");
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
		paysort.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		paysort.get_style_context().add_class("xx");

		iobar.get_style_context().add_provider(iobcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		iobar.get_style_context().add_class("xx");

		Gtk.MenuButton savemenu = new Gtk.MenuButton();
		Gtk.MenuButton loadmenu = new Gtk.MenuButton();
		savemenu.icon_name = "document-save-symbolic";
		loadmenu.icon_name = "document-open-symbolic";

		savemenu.get_first_child().get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		savemenu.get_first_child().get_style_context().add_class("xx");
		loadmenu.get_first_child().get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		loadmenu.get_first_child().get_style_context().add_class("xx");

		Gtk.GestureClick loadmenuclick = new Gtk.GestureClick();
		loadmenu.add_controller(loadmenuclick);


		Gtk.Button savebutton = new Gtk.Button.with_label("save");
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
		saveentry.text = "export";
		savepopbox.append(saveentry);
		savepopbox.append(savebutton);
		savepop.set_child(savepopbox);
		loadpop.set_child(loadpopbox);
		savemenu.popover = savepop;
		loadmenu.popover = loadpop;
		iobar.pack_start(loadmenu);
		iobar.pack_end(savemenu);

		savepop.get_first_child().get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		savepop.get_first_child().get_style_context().add_class("xx");
		loadpop.get_first_child().get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		loadpop.get_first_child().get_style_context().add_class("xx");

//events
		visaflt.activate.connect(() => {getflts(); snorts(snortidx); renderdat();});
		visasort.clicked.connect(() => {getflts(); snortidx = 0; snorts(0); renderdat();});
		jobflt.activate.connect(() => {getflts(); snorts(snortidx); renderdat();});
		jobsort.clicked.connect(() => {getflts(); snortidx = 1; snorts(1); renderdat();});
		socflt.activate.connect(() => {getflts(); snorts(snortidx); renderdat();});
		socsort.clicked.connect(() => {getflts(); snortidx = 2; snorts(2); renderdat();});
		startflt.activate.connect(() => {getflts(); snorts(snortidx); renderdat();});
		startsort.clicked.connect(() => {getflts(); snortidx = 3; snorts(3); renderdat();});
		employerflt.activate.connect(() => {getflts(); snorts(snortidx); renderdat();});
		employersort.clicked.connect(() => {getflts(); snortidx = 4; snorts(4); renderdat();});
		cityflt.activate.connect(() => {getflts(); snorts(snortidx); renderdat();});
		citysort.clicked.connect(() => {getflts(); snortidx = 5; snorts(5); renderdat();});
		stateflt.activate.connect(() => {getflts(); snorts(snortidx); renderdat();});
		statesort.clicked.connect(() => {getflts(); snortidx = 6; snorts(6); renderdat();});
		payflt.activate.connect(() => {getflts(); snorts(snortidx); renderdat();});
		paysort.clicked.connect(() => {getflts(); snortidx = 7; snorts(7); renderdat();});
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
								muh.get_style_context().add_provider(butcsp, Gtk.STYLE_PROVIDER_PRIORITY_USER);
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
									getflts();
									loaddat(buh.label);
									fiolabel.label = "%s has %d records".printf(buh.label,dat.length);
									renderdat();
									loadpop.popdown();
								});
							}
						}
					}
					Gtk.CheckButton tst = new Gtk.CheckButton.with_label("testrun");
					tst.toggled.connect((yn) => {
						testrun = yn.get_active();
					});
					loadpopbox.append(tst);
				}
				doup = true;
			}			
		});

		nxn.hexpand = true;
		nxn.vexpand = true;
		contentscroll.set_child(nxn);
		content.append(contentscroll);
		container.append(fileio);
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