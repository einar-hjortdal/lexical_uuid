module luuid

import math as m
import rand as r
import strconv as s
import time as t

const luuid_length = 32
const hyphen_indexes = [8, 13, 18, 23]
const luuid_length_with_hyphens = luuid_length + hyphen_indexes.len

// TODO mutex?
pub struct Generator {
mut:
	current_ts t.Time
	counter    int
}

// new_generator is the factory function that returns a new Generator.
// Always prefer utilizing the factory function.
pub fn new_generator() &Generator {
	return &Generator{}
}

// verify_ts potentially modifies generator fields, it must be invoked before using generator fields
// during the generation process.
fn (mut gen Generator) verify_ts(ts t.Time, duration t.Duration) {
	// TODO if ts > gen.current_ts there was an anomaly: hang generation, then continue.
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
			// TODO if exceeded, hang until clock increment.
			gen.counter++
		} else {
			gen.current_ts = ts
			gen.counter = 0
		}
	}
}

fn verify_lacks_hyphens(id string) ! {
	if id.count('-') != 0 {
		return error('Malformed LUUID')
	}
}

// add_hyphens adds hyphens to a LUUID without hyphens.
pub fn add_hyphens(id string) !string {
	if id.len != luuid.luuid_length {
		return error('ID too long or too short')
	}
	verify_lacks_hyphens(id)!

	mut res := id

	len := luuid.hyphen_indexes.len
	for i := 0; i < len; i++ {
		hyphen_index := luuid.hyphen_indexes[i]
		res = res[..hyphen_index] + '-' + res[hyphen_index..]
	}
	return res
}

fn build_result(binary_string string) !string {
	mut hex_res := ''
	for i := 0; i < 128; i += 4 {
		// parse character
		character := binary_string[i..i + 4]
		to_int := s.parse_uint(character, 2, 4) or { return error('Could not parse integer') }
		to_hex := to_int.hex()
		hex_res += to_hex
	}
	res := add_hyphens(hex_res)!
	return res
}

fn pad_left_with_zeroes(binary_string string, desired_length int) !string {
	if binary_string.len > desired_length {
		return error('binary_string longer than desired.')
	}

	mut res := binary_string
	for res.len < desired_length {
		res = '0${res}'
	}
	return res
}

fn generate_random_bits(desired_length int) string {
	mut res := ''
	for res.len < desired_length {
		new_bit := r.intn(2) or { 0 }
		res += '${new_bit}'
	}
	return res
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
	* Seconds since 1st January 1970, can represent dates until the year 4147
	*/
	unpadded_unixts := s.format_uint(u64(gen.current_ts.unix()), 2)
	unixts := pad_left_with_zeroes(unpadded_unixts, 36)!

	/*
	* nsec
	* 38 bits
	*
	* The nanosecond field is supposed to be a fraction, not the number of nanoseconds.
	*/
	sec := f64(gen.current_ts.nanosecond) / 1_000_000_000
	// scale_factor ensures that the binary representation utilizes a maximum of 38 bits.
	scale_factor := m.exp2(38)
	float_nsec := sec / (1.0 / scale_factor)
	int_nsec := u64(float_nsec)
	unpadded_nsec := s.format_uint(int_nsec, 2)
	nsec := pad_left_with_zeroes(unpadded_nsec, 38)!

	/*
	* ver
	*
	* Version is set to 1 because it is the first implementation of the Lexical UUID.
	* 0     0     0     1
	*/
	ver := '0001'

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
	unpadded_seq := s.format_int(gen.counter, 2)
	seq := pad_left_with_zeroes(unpadded_seq, 8)!

	/*
	* rand
	* 42 bits
	*/
	rand := generate_random_bits(42)

	/*
	* result
	*/
	nsec_1 := nsec[0..12]
	nsec_2 := nsec[12..38]

	bin_res := '${unixts}${nsec_1}${ver}${nsec_2}${seq}${rand}'

	return build_result(bin_res)!
}

fn verify_luuid_length(id string) ! {
	if id.len != luuid.luuid_length && id.len != luuid.luuid_length_with_hyphens {
		return error('The provided ID is too long or too short')
	}
}

fn verify_hypens_amount(id string) ! {
	if id.count('-') != 4 {
		return error('Unexpected number of hyphens')
	}
}

fn verify_hypens_position(id string) ! {
	for idx in luuid.hyphen_indexes {
		if id[idx] != 45 { // ascii 45 is a hyphen
			return error('Hyphen missing or in wrong position')
		}
	}
}

// verify accepts LUUID with or without hyphens.
// Returns the binary representation of the string for further parsing.
// Returns an error if the string does not match the expected format.
// This function is useful to verify whether a string is a seemingly-valid UUID.
fn verify(id string) !string {
	verify_luuid_length(id)!
	if id.len == luuid.luuid_length_with_hyphens {
		verify_hypens_amount(id)!
		verify_hypens_position(id)!
		luuid_without_hyphens := id.replace('-', '')
		return hex_to_bin(luuid_without_hyphens)
	}

	verify_lacks_hyphens(id)!
	return hex_to_bin(id)
}

// hex_to_bin returns a binary string from the given hex string.
fn hex_to_bin(id string) !string {
	mut bin := ''
	chars := id.split('')
	for c in chars {
		parsed_hex := c.parse_int(16, 64)!
		mut res := s.format_int(parsed_hex, 2)
		// pad left
		for res.len < 4 {
			res = '0${res}'
		}
		bin += res
	}
	return bin
}

struct Luuid {
	timestamp t.Time
	version   int
}

fn parse_v1(id string) !Luuid {
	return error('TODO not implemented')
}

fn parse_v2(id string) !Luuid {
	return error('TODO not implemented')
}

pub fn parse(id string) !Luuid {
	bin := verify(id)!
	version := bin[48..52]
	if version == '0001' {
		return parse_v1(id)
	}
	if version == '0010' {
		return parse_v2(id)
	}
	return error('The ID is not a Luuid')
}

/*
*
* Version 2
*
*/

// v2 does not use a generator and does not contain monotonic counter bits.
pub fn v2() !string {
	ts := t.utc()
	mut unixts := s.format_uint(u64(ts.unix()), 2)
	for unixts.len < 36 {
		unixts = '0${unixts}'
	}

	sec := f64(ts.nanosecond) / 1_000_000_000
	scale_factor := m.exp2(38)
	float_nsec := sec / (1.0 / scale_factor)
	int_nsec := u64(float_nsec)
	bin_nsec := s.format_uint(int_nsec, 2)

	mut nsec := bin_nsec
	for nsec.len < 38 {
		nsec = '0${nsec}'
	}

	ver := '0010'

	mut rand := ''
	for rand.len < 50 {
		new_bit := r.intn(2) or { 0 }
		rand += '${new_bit}'
	}

	nsec_1 := nsec[0..12]
	nsec_2 := nsec[12..38]

	bin_res := '${unixts}${nsec_1}${ver}${nsec_2}${rand}'

	return build_result(bin_res)!
}
