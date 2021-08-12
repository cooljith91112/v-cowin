import json
import net.http
import os
import time

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



fn main() {
	//state_id := 17
	district_id := 296
	mut date_of_vaccine := time.now().add_days(1).get_fmt_date_str(.hyphen,.ddmmyyyy)
	if os.args.len == 2 {
		date_of_vaccine = os.args[1]
	} 

	println("Searching Vaccine Availability on $date_of_vaccine")
	find_session(district_id, date_of_vaccine)
	setup_termui()
}

fn find_session(district_id int,date string) {
	mut available_sessions := []Sessions{}
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

	available_sessions := session_data.sessions.filter(it.available_capacity > 0 && it.min_age_limit<45)

	if available_sessions.len > 0 {
		println("Vaccines Available 😍😎")
	} else {
		println("No Vaccines Available 😢")
	}
}

fn setup_termui() {

}