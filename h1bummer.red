Red [ needs 'view ]

;  HIB xlsx columns as of 2019

;  01 : CASE_NUMBER
;  02 : CASE_STATUS
;  03 : CASE_SUBMITTED
;  04 : DECISION_DATE
;  05 : VISA_CLASS
;  06 : EMPLOYMENT_START_DATE
;  07 : EMPLOYMENT_END_DATE
;  08 : EMPLOYER_NAME
;  09 : EMPLOYER_BUSINESS_DBA
;  10 : EMPLOYER_ADDRESS
;  11 : EMPLOYER_CITY
;  12 : EMPLOYER_STATE
;  13 : EMPLOYER_POSTAL_CODE
;  14 : EMPLOYER_COUNTRY
;  15 : EMPLOYER_PROVINCE
;  16 : EMPLOYER_PHONE
;  17 : EMPLOYER_PHONE_EXT
;  18 : SECONDARY_ENTITY
;  19 : SECONDARY_ENTITY_BUSINESS_NAME
;  20 : AGENT_REPRESENTING_EMPLOYER
;  21 : AGENT_ATTORNEY_NAME
;  22 : AGENT_ATTORNEY_CITY
;  23 : AGENT_ATTORNEY_STATE
;  24 : JOB_TITLE
;  25 : SOC_CODE
;  26 : SOC_NAME
;  27 : NAICS_CODE
;  28 : TOTAL_WORKERS
;  29 : NEW_EMPLOYMENT
;  30 : CONTINUED_EMPLOYMENT
;  31 : CHANGE_PREVIOUS_EMPLOYMENT
;  32 : NEW_CONCURRENT_EMP
;  33 : CHANGE_EMPLOYER
;  34 : AMENDED_PETITION
;  35 : FULL_TIME_POSITION
;  36 : PREVAILING_WAGE
;  37 : PW_UNIT_OF_PAY
;  38 : PW_WAGE_LEVEL
;  39 : PW_SOURCE
;  40 : PW_SOURCE_YEAR
;  41 : PW_SOURCE_OTHER
;  42 : WAGE_RATE_OF_PAY_FROM
;  43 : WAGE_RATE_OF_PAY_TO
;  44 : WAGE_UNIT_OF_PAY
;  45 : H1B_DEPENDENT
;  46 : WILLFUL_VIOLATOR
;  47 : SUPPORT_H1B
;  48 : STATUTORY_BASIS
;  49 : APPENDIX_ATTACHMENT
;  50 : LABOR_CON_AGREE
;  51 : PUBLIC_DISCLOSURE_LOCATION
;  52 : WORKSITE_CITY
;  53 : WORKSITE_COUNTY
;  54 : WORKSITE_STATE
;  55 : WORKSITE_POSTAL_CODE
;  56 : ORIGINAL_CERT_DATE

;; Red GC is temperamental atm...
recycle/off

noupdate: false

sw: now/time/precise
ew: now/time/precise

d: copy [] ; source data
o: copy [] ; processed data
r: copy [] ; rendered data

fos: 6 ; width of each character in pixels. consolas 8 = 6pix, plus 1 between chars
fpad: 3 ; padding before characters in a field, in pixels

asb: 1 ; am sorting by this column of processed data
delt: false ; reverse sorting?

readmemyxlsx: function [ f ] [
	probe f
]

sortlist: func [ c ] [
	if (length? o) > 0 [
		fi: o/1/:c
		probe fi
		delt: true
		foreach z o [ delt: (z/:c < fi) fi: z/:c if delt [ break ] ]
		either delt [
			sort/compare o func [ a b ] [
				case [
					a/:c > b/:c [-1]
					a/:c < b/:c [1]
					a/:c = b/:c [0]
				]
			]
		] [
			sort/compare o func [ a b ] [
				case [
					a/:c > b/:c [1]
					a/:c < b/:c [-1]
					a/:c = b/:c [0]
				]
			]
		]
		remove-each k r [ true ]
		foreach g o [ append r rejoin g ]
		clear ll/data
		ll/data: copy r
		asb: c
	]
]

filterlist: func [ ] [

	; fields are : (p)ay (e)mployer (t)itle (v)isa (s)tate (c)ategory

	ck: copy [ false false false false false false ] ; checks for filtering using filter field, false = don't do it
	ns: copy [ "" "" "" "" "" "" ] ; strings to use for filtering
	ci: copy [ 42 8 24 5 12 26 ] ; h1bdata columns matching the fields
; get field content
	unless none? fp/text [ ns/1: to-integer (trim copy fp/text) ]
	unless none? fe/text [ ns/2: trim copy fe/text ]
	unless none? ft/text [ ns/3: trim copy ft/text ]
	unless none? fv/text [ ns/4: trim copy fv/text ]
	unless none? fs/text [ ns/5: trim copy fs/text ]
	unless none? fc/text [ ns/6: trim copy fc/text ]
; set checks based on valid field content
	repeat n 6 [ if ns/:n <> "" [ ck/(n): true ] ]
; cleanup storage blocks
	remove-each k o [ true ]
	remove-each k r [ true ]
; loop through records
	repeat x (length? d) [
	;repeat x 10 [
		doit: true
; filtering. using parse as it was fastest in tests (but still way too slow)
		repeat n 6 [ 
			if n > 1 [
				if ck/:n = true [
					ss: copy ns/:n
				    unless (parse d/:x/(ci/(n)) [ to ss to end ]) [ doit: false break ]
				]
			]
		]
		if doit [
; process pay
			dd: 0.0
			catch [ 
				either error? try [ to-float (trim d/:x/42) ] [ 
					throw dd: 0.0
				] [ 
					dd: to-float (trim d/:x/42)
				]
			]
; filter using pay threshold, hourly based on traditional 8-hour, 5-day, paid holidays. 
; for artists in USA its more like 10-hour, 6-day, unpaid holiday, so fudge these if you want more realistinc numbers
			if ck/1 [
				if (lowercase (trim d/:x/44)) = "year" [
					if ((to-integer dd) < ns/1) [ doit: false ]
				]
				if (lowercase (trim d/:x/44)) = "hour" [
					if ((to-integer (((dd * 8.0) * 5.0) * 52.0)) < ns/1) [ doit: false]
				]
			]
			m: round/to dd 0.1
			if m = none [ m: 0.0 ]
; store the processed data
			append/only o compose/deep [ 
				(m)
				(reduce d/(x)/44)
				(reduce d/(x)/8) 
				(reduce d/(x)/24)
				(reduce d/(x)/5)
				(reduce d/(x)/12)
				(reduce d/(x)/26) 
			]
		]
	]
; default sort by pay
	either (length? o) > 0 [
		either delt [
			sort/compare o func [ a b ] [
				case [
					a/:asb > b/:asb [-1]
					a/:asb < b/:asb [1]
					a/:asb = b/:asb [0]
				]
			]
		] [
			sort/compare o func [ a b ] [
				case [
					a/:asb > b/:asb [1]
					a/:asb < b/:asb [-1]
					a/:asb = b/:asb [0]
				]
			]
		]
; padding. this is a sloppy just-get-it-done 2-loop process atm, it should probably be part of the main loop above
		pads: copy []
		repeat u (length? o/1) [ either u = 1 [ append pads length? (to-string o/1/:u) ] [ append pads length? o/1/:u ] ]
		pads/6: max pads/6 8 ; prevent clipping
		;probe pads
		foreach x o [
			repeat l (length? pads) [
				either (l = 1) [
					pads/:l: max (length? (to-string x/:l)) pads/:l
				] [
					pads/:l: max (length? x/:l) pads/:l
				]
			]
		]
		repeat x (length? o) [
			repeat l (length? pads) [
				o/:x/:l: rejoin [ (pad o/:x/:l (pick pads l)) "   " ]
			]
		]
		foreach g o [ append r rejoin g ]
; ui
		clear ll/data
		ll/data: copy r
		fp/offset/x: 0
	    fp/size/x: to-integer ((pads/1 + 3 + pads/2 + 3) * fos) + fpad
		fe/offset/x: fp/size/x
		fe/size/x: to-integer ((pads/3 + 3) * fos)
		ft/offset/x: fe/offset/x + fe/size/x
		ft/size/x: to-integer ((pads/4 + 3) * fos)
		fv/offset/x: ft/offset/x + ft/size/x
		fv/size/x: to-integer ((pads/5 + 3) * fos)
		fs/offset/x: fv/offset/x + fv/size/x
		fs/size/x: to-integer ((pads/6 + 3) * fos)
		fc/offset/x: fs/offset/x + fs/size/x
		fc/size/x: to-integer ((pads/7 + 3) * fos)
		bp/offset/x: fp/offset/x
		bp/size/x: fp/size/x
		be/offset/x: fe/offset/x
		be/size/x: fe/size/x
		bt/offset/x: ft/offset/x
		bt/size/x: ft/size/x
		bv/offset/x: fv/offset/x
		bv/size/x: fv/size/x
		bs/offset/x: fs/offset/x
		bs/size/x: fs/size/x
		bc/offset/x: fc/offset/x
		bc/size/x: fc/size/x
		print "filtering is done."
	] [
		ll/data: r
		print "filtering (empty) is done."
	]
]

view/tight/flags/options [
	title "H1Bummer"
	below
	hh: panel 800x55 35.35.35 [
		text 100x30 "file" font-name "consolas" font-size 24 font-color 80.80.80 bold
		xls: drop-list 300x20 font-name "consolas" font-size 10 font-color 128.128.128 data (collect [ foreach file read %./ [ if (find (to-string file) ".rb") [keep rejoin ["./" (to-string file)]] ]]) on-change [
			unless noupdate [
				clear d
				d: load to-file rejoin [ "./" face/data/(face/selected) ]
				print [ face/data/(face/selected) "has" (length? d) "records" ]
				inf/text: rejoin [ " = " (length? d) " records" ]
				filterlist
			]
		]
		inf: text 200x30 "(none)" font-name "consolas" font-size 12 font-color 80.80.80 bold
	    exd: button 100x33 "export" font-name "consolas" font-size 12 font-color 200.200.200 bold [
			if (length? o) > 0 [
				csv: copy []
			    foreach i o [
				    rl: copy ""
					foreach h i [
						either string? h [ rl: rejoin [ rl (trim h) "; " ] ] [ rl: rejoin [ rl (to-string h) "; " ] ]
					]
					take/last rl take/last rl
				    append csv rl
				]
				probe csv
				write/lines %./exported.csv csv
			]
		]
	]
	ff: panel 800x35 35.35.35 font-name "consolas" font-size 12 font-color 80.80.80 bold [
		fp: field 120x30 with [ text: "80000" ]  font-name "consolas" font-size 12 font-color 200.200.200 bold on-enter [ 
			catch [ 
				either error? try [ to-integer face/text ] [ 
					throw face/text: "80000" filterlist
				] [ 
					filterlist
				]
			]
		]
		fe: field 120x30  font-name "consolas" font-size 12 font-color 200.200.200 bold on-enter [ filterlist ]
		ft: field 120x30 with [ text: "ARTIST" ] font-name "consolas" font-size 12 font-color 200.200.200 bold on-enter [ filterlist ]
		fv: field 120x30 with [ text: "E-3" ] font-name "consolas" font-size 12 font-color 200.200.200 bold on-enter [ filterlist ]
		fs: field 120x30 with [ text: "CA" ] font-name "consolas" font-size 12 font-color 200.200.200 bold on-enter [ filterlist ]
		fc: field 120x30 with [ text: "ARTIST" ] font-name "consolas" font-size 12 font-color 200.200.200 bold on-enter [ filterlist ]
	]
	bb: panel 800x35 35.35.35 font-name "consolas" font-size 12 font-color 80.80.80 bold [
		bp: button 120x30 "PAY" font-name "consolas" font-size 12 font-color 200.200.200 bold [ sortlist 1 ]
	    be: button 120x30 "EMPLOYER" font-name "consolas" font-size 12 font-color 200.200.200 bold [ sortlist 3 ]
		bt: button 120x30 "TITLE" font-name "consolas" font-size 12 font-color 200.200.200 bold [ sortlist 4 ]
		bv: button 120x30 "VISA" font-name "consolas" font-size 12 font-color 200.200.200 bold [ sortlist 5 ]
		bs: button 120x30 "LOC" font-name "consolas" font-size 12 font-color 200.200.200 bold [ sortlist 6 ]
		bc: button 120x30 "CATEGORY" font-name "consolas" font-size 12 font-color 200.200.200 bold [ sortlist 7 ]
	]
	pp: panel 800x500 [
		ll: text-list 800x500 font-name "consolas" font-size 8 font-color 128.128.128 bold
	]
	do [
		ll/offset: 0x0
		fp/offset/y: 0
		fe/offset/y: 0
		ft/offset/y: 0
		fv/offset/y: 0
		fs/offset/y: 0
		fc/offset/y: 0
		bp/offset/y: 0
		be/offset/y: 0
		bt/offset/y: 0
		bv/offset/y: 0
		bs/offset/y: 0
		bc/offset/y: 0
		
	]
] [ resize ] [
	actors: object [
		on-resizing: function [ face event ] [
			exd/offset/x: face/size/x - 110
			hh/size/x: face/size/x
			ff/size/x: face/size/x
			bb/size/x: face/size/x
			pp/size/x: face/size/x
			ll/size/x: pp/size/x
			pp/size/y: face/size/y - (hh/size/y + ff/size/y + bb/size/y)
			ll/size/y: pp/size/y
		]
	]
]
