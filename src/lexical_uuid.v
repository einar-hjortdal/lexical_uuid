module lexical_uuid

import math as m
import rand as r
import strconv as s
import time as t

pub struct Generator {
mut:
	current_ts t.Time
	counter    int
}

// new_generator is the factory function that returns a new Generator. Always prefer utilizing the factory
// function.
pub fn new_generator() &Generator {
	return &Generator{}
}

// verify_ts potentially modifies generator fiels, it must be invoked before using generator fields
// during the generation process.
fn (mut gen Generator) verify_ts(ts t.Time, duration t.Duration) {
	if ts == gen.current_ts {
		// Rollover if counter exceeds capacity
		if gen.counter == 255 {
			gen.current_ts = ts.add(duration)
			gen.counter = 0
		} else {
			gen.counter++
		}
	} else {
		// Generating past the rollover
		if ts < gen.current_ts && gen.current_ts == ts.add(duration) {
			// This handles only one rollover, it is assumed the counter may be needed in bursts, not continuously.
			// Totals up to 510 billion Lexical UUID v1 per second.
			// Totals up to 510 million Lexical UUID v2 per second.
			gen.counter++
		} else {
			gen.current_ts = ts
			gen.counter = 0
		}
	}
}

fn build_result(binary_string string) !string {
	mut hex_res := ''
	dash_index := [32, 48, 64, 80]
	for i := 0; i < 128; i += 4 {
		// add dash
		if i in dash_index {
			hex_res += '-'
		}
		// parse character
		character := binary_string[i..i + 4]
		to_int := s.parse_uint(character, 2, 4) or {
			return error('Could not parse integer')
			// TODO do not return error
		}
		to_hex := to_int.hex()
		hex_res += to_hex
	}
	return hex_res
}

/*
*
* Version 1
*
*/

pub fn (mut gen Generator) v1() !string {
	ts := t.utc()
	gen.verify_ts(ts, 1 * t.nanosecond)

	/*
	* unixts
	* 36 bits
	*
	* Seconds since 1st January 1970
	*/
	mut unixts := s.format_uint(u64(gen.current_ts.unix), 2)

	// Pad with 0s to the left if output is shorter than 36
	for unixts.len < 36 {
		unixts = '0${unixts}'
	}

	/*
	* nsec
	* 38 bits
	*
	* The nanosecond field is supposed to be a fraction as opposed to the specific number of nanoseconds.
	*/
	sec := f64(gen.current_ts.nanosecond) / 1_000_000_000
	// scale_factor ensures that the binary representation utilizes a maximum of 38 bits.
	scale_factor := m.exp2(38)
	float_nsec := sec / (1.0 / scale_factor)
	int_nsec := u64(float_nsec)
	bin_nsec := s.format_uint(int_nsec, 2)

	// Padding ensures that the binary representation always utilizes 38 bits.
	mut nsec := bin_nsec
	for nsec.len < 38 {
		nsec = '0${nsec}'
	}

	/*
	* ver
	*
	* This is the implementation of a rejected UUID version 7.
	* Version is set to 1 because it is the first implementation of the Lexical UUID.
	* 0     0     0     1
	*/
	ver := '0001'

	/*
	* var
	*
	* This is the implementation of a rejected UUID version 7.
	* It does not conform to any official standard, but it pretends to do so because it was meant to.
	* 1     0     x
	*/
	var := '10'

	/*
	* seq
	* 8 bits
	*
	* This sequence must start at zero and increment monotonically for each new Lexical UUID created by
	* the application on the same timestamp. When the timestamp increments the clock sequence must be
	* reset to zero. The clock sequence MUST NOT rollover or reset to zero unless the timestamp has incremented.
	*
	* The maximum number of generations per nanosecond is of 255 (111111 or FF). Exceeding 255 generations
	* per nanosecond is very unlikely.
	*
	* Counter increment and rollover is handled by `gen.verify_ts`.
	*/
	mut seq := s.format_int(gen.counter, 2)

	// Padding ensures that the binary representation of the counter always utilizes 8 bits.
	for seq.len < 8 {
		seq = '0${seq}'
	}

	/*
	* rand
	* 40 bits
	*/
	mut rand := ''
	for rand.len < 40 {
		new_bit := r.intn(2) or { 0 }
		rand += '${new_bit}'
	}

	/*
	* result
	*/
	nsec_1 := nsec[0..12]
	nsec_2 := nsec[12..24]
	nsec_3 := nsec[24..38]

	bin_res := '${unixts}${nsec_1}${ver}${nsec_2}${var}${nsec_3}${seq}${rand}'

	return build_result(bin_res)!
}

pub fn parse_v1() {
	// from binary to number of nanoseconds:
	// back_1 := s.parse_uint(bin_nsec, 2, 64) or { panic(err) }
	// back_2 := back_1 * divisor
	// println(back_1)
	// println(u64(m.round(back_2 * 1000000000)))
}

/*
*
* Version 2
*
*/

pub fn (mut gen Generator) v2() !string {
	ts := t.utc()
	gen.verify_ts(ts, 1 * t.microsecond)

	/*
	* adjts
	* 32 bits
	*
	* Seconds since 1st January 2020.
	*/
	modern_epoch := 1577836800

	int_adjts := gen.current_ts.unix - modern_epoch
	mut adjts := s.format_uint(u64(int_adjts), 2)

	// Pad with 0s to the left if output is shorter than 32
	for adjts.len < 32 {
		adjts = '0${adjts}'
	}

	/*
	* µsec
	* 20 bits
	*
	* The specific number of microseconds.
	*/
	int_microsec := gen.current_ts.nanosecond / 1000
	mut microsec := s.format_uint(u64(int_microsec), 2)

	// Pad with 0s to the left if output is shorter than 20
	for microsec.len < 20 {
		microsec = '0${microsec}'
	}

	/*
	* seq
	* 8 bits
	*/
	mut seq := s.format_int(gen.counter, 2)

	// Padding ensures that the binary representation of the counter always utilizes 8 bits.
	for seq.len < 8 {
		seq = '0${seq}'
	}

	/*
	* rand
	* 68 bits
	*/
	mut rand := ''
	for rand.len < 68 {
		new_bit := r.intn(2) or { 0 }
		rand += '${new_bit}'
	}

	/*
	* result
	*/
	bin_res := '${adjts}${microsec}${seq}${rand}'

	return build_result(bin_res)!
}

pub fn parse_v2() {
}
