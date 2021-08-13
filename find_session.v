import json
import net.http
import os
import time
import term
import term.ui as tui

struct StatesResponse {
	states []State
}

struct State {
	state_id int
	state_name string
}

struct DistrictResponse {
	districts []District
}

struct District {
	district_id int
	district_name string
}

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
	state_id  int
	district_id int
	state State
	district District
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
	app.tui.draw_text(3,2, term.bold(term.bright_magenta("Vaccine Availability on ${app.data.date} | ${app.data.state.state_name},${app.data.district.district_name} | Total Centers : ${app.data.available_sessions.len}")))
	app.tui.horizontal_separator(3)
}

fn (mut app App) draw_vaccine_availability() {
	available_sessions := app.data.available_sessions
	start_x := 3
	mut start_y := 5
	if available_sessions.len == 0 {
		app.tui.draw_text(app.tui.window_width/2 - 10,app.tui.window_height/2, term.black(term.bg_white("No Vaccine Available")))
	} else {
		for session in available_sessions {
			fee := match session.fee_type{
				'Free' {term.green('Free')}
				'Paid' {term.blue(session.fee)  }
				else { 'N/A' }
			}
			vaccine := match session.vaccine {
				'COVISHIELD' {term.bold(term.green(session.vaccine))}
				'COVAXIN' {term.bold(term.yellow(session.vaccine))}
				else {session.vaccine}
			}
			capacity := term.green(session.available_capacity.str())
			app.tui.draw_text(start_x,start_y,"${session.name} | Vaccine: ${vaccine} | Total Available: ${capacity} | Fee: ${fee}")
			start_y += 2
		}
	}
}

fn init(x voidptr) {
	mut app := &App(x)
	app.find_session(app.data.district_id, app.data.date)
}

fn main() {
	setup_states()
}

fn get_states() ?[]State {
	fetch_config := http.FetchConfig{
		header: http.new_header(
				key : .accept_language,
				value: 'en-US'
		)
	}

	url := 'https://cdn-api.co-vin.in/api/v2/admin/location/states'
	resp := http.fetch(url, fetch_config) or {
		term.clear()
		println(term.fail_message('Failed to fetch States from the server'))
		return error('Failed to fetch States from the server')
	}

	states_data := json.decode(StatesResponse, resp.text) or {
		term.clear()
		println(term.fail_message('Failed to decode data from server'))
		return error('Failed to decode data from server')
	}		
	return states_data.states
}

fn get_districts(state_id int) ?[]District {
	fetch_config := http.FetchConfig{
		header: http.new_header(
				key : .accept_language,
				value: 'en-US'
		)
	}

	url := 'https://cdn-api.co-vin.in/api/v2/admin/location/districts/$state_id'
	resp := http.fetch(url, fetch_config) or {
		term.clear()
		println(term.fail_message('Failed to fetch Districts from the server'))
		return error('Failed to fetch Districts from the server')
	}

	district_data := json.decode(DistrictResponse, resp.text) or {
		term.clear()
		println(term.fail_message('Failed to decode data from server'))
		return error('Failed to Decode data from the server')
	}		
	return district_data.districts
}

fn (mut app App) find_session(district_id int,date string) {
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
		println(term.fail_message('Failed to decode data'))
		return
	}

	app.data.available_sessions = session_data.sessions.filter( it.available_capacity > 0 && it.min_age_limit<45)
}

fn setup_termui(state State, district District) {
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
	app.data.state = state
	app.data.district = district
	app.data.state_id = state.state_id
	app.data.district_id = district.district_id
	app.tui.set_window_title("COWIN Vaccine Finder")
	app.tui.run() or {}
}

fn setup_states() {
	term.clear()
    width, height := term.get_terminal_size()
	println(term.header('Available State', '='))
	start_x :=  width/2 - 10
	mut start_y := 5
	mut selected_state := 0
    term.set_cursor_position(x: start_x, y: start_y)

	states := get_states() or {
		return
	}

	for i in 0 .. states.len {
		println(term.bright_green('$i . ${states[i].state_name}'))
		start_y += 1
		term.set_cursor_position(x: start_x, y: start_y)
	}
	term.set_cursor_position(x: 0, y: height)
	
	for {
        if var := os.input_opt('Please select a State: ') {
            if var.int() < 0 || var.int() >= states.len {
                continue
            }
			setup_districts(states[var.int()])
            break
        }
        println('')
        break
    }
	
}

fn setup_districts(state State) {
	term.clear()
    width, height := term.get_terminal_size()
	println(term.header('Available States', '='))
	start_x :=  width/2 - 10
	mut start_y := 5
    term.set_cursor_position(x: start_x, y: start_y)
	districts := get_districts(state.state_id) or {
		return
	}

	for i in 0 .. districts.len {
		println(term.bright_green('$i . ${districts[i].district_name}'))
		start_y += 1
		term.set_cursor_position(x: start_x, y: start_y)
	}
	term.set_cursor_position(x: 0, y: height)
	for {
        if var := os.input_opt('Please select a District: ') {
            if var.int() < 0 || var.int() >= districts.len {
                continue
            }
			setup_termui(state,districts[var.int()])
            break
        }
        println('')
        break
    }
	
}