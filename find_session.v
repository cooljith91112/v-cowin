import json
import net.http
import os
import time
import term.ui as tui

struct App {
mut:
    tui &tui.Context = 0
    data VaccineAvailability
	is_loading bool
	idx int = 1
}

struct VaccineAvailability {
mut:
	date string
	available_sessions []Sessions
	state_id  int = 17
	district_id int = 296
}

struct SessionResponse {
	sessions []Sessions
}

struct Sessions {
	center_id int
	name string
	address	string
	state_name string
	district_name string
	block_name	string
	pincode	int
	from string
	to string
	lat int
	long int
	fee_type string
	session_id string
	date string
	available_capacity int
	available_capacity_dose1 int
	available_capacity_dose2 int
	fee	 string
	allow_all_age bool
	min_age_limit int
	vaccine	string
	slots []string
}

fn event(e &tui.Event, x voidptr) {
    mut app := &App(x)
	if e.typ == .key_down && e.code == .escape {
        exit(0)
    }

	if e.typ == .key_down && e.code == .enter {
		app.idx = app.idx + 1
		mut date_of_vaccine := time.now().add_days(app.idx).get_fmt_date_str(.hyphen,.ddmmyyyy)
		app.data.date = date_of_vaccine
		app.find_session(app.data.district_id, app.data.date)
	}
}

fn frame(x voidptr) {
    mut app := &App(x)
	app.tui.clear()
	//Draw Area
	app.draw_header()
	app.draw_vaccine_availability()
	app.tui.reset()
    app.tui.flush()
}

fn (mut app App) draw_header() {
	app.tui.draw_text(3,2,"Vaccine Availability on ${app.data.date} | Total Centers : ${app.data.available_sessions.len}")
	app.tui.horizontal_separator(3)
}

fn (mut app App) draw_vaccine_availability() {
	available_sessions := app.data.available_sessions
	start_x := 3
	mut start_y := 5
	if available_sessions.len == 0 {
		app.tui.draw_text(app.tui.window_width/2 - 10,app.tui.window_height/2,"No Vaccine Available")
	} else {
		for session in available_sessions {
			fee := match session.fee_type{
				'Free' {'Free'}
				'Paid' { session.fee }
				else { 'N/A' }
			}
			app.tui.draw_text(start_x,start_y,"${session.address} | Vaccine: ${session.vaccine} | Total Available: ${session.available_capacity} | Fee: ${fee}")
			start_y += 2
		}
	}
}

fn init(x voidptr) {
	mut app := &App(x)
	app.find_session(app.data.district_id, app.data.date)
}


fn main() {
	mut app := &App{}
	app.tui = tui.init(
		user_data: app
		event_fn: event
		frame_fn: frame
		hide_cursor: false,
		init_fn: init
	)
	mut date_of_vaccine := time.now().add_days(app.idx).get_fmt_date_str(.hyphen,.ddmmyyyy)
	if os.args.len ==2 {
		date_of_vaccine = os.args[1]
	} 

	println("Searching Vaccine Availability on $date_of_vaccine")
	app.data.date = date_of_vaccine
	app.tui.set_window_title("COWIN Vaccine Finder")
	app.tui.run() ?
}

fn (mut app App) find_session(district_id int,date string) {
	app.is_loading = true
	fetch_config := http.FetchConfig{
		header: http.new_header(
				key : .accept_language,
				value: 'en-US'
		)
	}

	url := 'https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/findByDistrict?district_id=$district_id&date=$date'

	resp := http.fetch(url, fetch_config) or {
		println('failed to fetch data from the server')
		return
	}

	session_data := json.decode(SessionResponse, resp.text) or {
		println('failed to decode session json')
		return
	}

	app.data.available_sessions = session_data.sessions
											.filter( it.available_capacity > 0 && it.min_age_limit<45)
	app.is_loading = false
}

fn setup_termui() {
	
}