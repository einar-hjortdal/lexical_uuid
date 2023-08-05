module lexical_uuid

import math as m
import rand as r
import strconv as s
import time as t

pub struct LexicalUUIDGenerator {
mut:
	current_ts string
	counter    int
}

// new_lexical_uuid_generator is the factory function that returns a new LexicalUUIDGenerator. Always
// prefer utilizing the factory function.
pub fn new_lexical_uuid_generator() &LexicalUUIDGenerator {
	return &LexicalUUIDGenerator{}
}

pub fn (mut gen LexicalUUIDGenerator) v1() !string {
	/*
	* unixts
	* 36 bits
	*
	* Seconds since 1st January 1970
	*/
	wall_ts := t.utc().unix_time()
	mut unixts := s.format_uint(u64(wall_ts), 2)
	// Pad with 0s to the right if output is shorter than 36
	for unixts.len < 36 {
		unixts = '0${unixts}'
	}

	/*
	* nsec
	* 38 bits
	*
	* The nanosecond field is supposed to be a fraction as opposed to the specific number of nanoseconds.
	*/
	// TODO change to wall clock nanoseconds once V implements it
	wall_nsec := t.sys_mono_now() % 1_000_000_000

	sec := f64(wall_nsec) / 1_000_000_000
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
	*/
	nano_ts := '${wall_ts}${wall_nsec}'
	if nano_ts == gen.current_ts {
		if gen.counter >= 255 {
			return error('Too many generations per nanosecond.')
		}
		gen.counter++
	} else {
		gen.current_ts = nano_ts
		gen.counter = 0
	}

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

	mut hex_res := ''
	dash_index := [32, 48, 64, 80]
	for i := 0; i < 128; i += 4 {
		// add dash
		if i in dash_index {
			hex_res += '-'
		}
		// parse character
		character := bin_res[i..i + 4]
		to_int := s.parse_uint(character, 2, 4) or { return error('Could not parse integer') }
		to_hex := to_int.hex()
		hex_res += to_hex
	}

	return hex_res
}

pub fn parse_v1() {
	// from binary to number of nanoseconds:
	// back_1 := s.parse_uint(bin_nsec, 2, 64) or { panic(err) }
	// back_2 := back_1 * divisor
	// println(back_1)
	// println(u64(m.round(back_2 * 1000000000)))
}

pub fn (mut gen LexicalUUIDGenerator) v2() !string {
	/*
	* adjts
	* 32 bits
	*
	* Seconds since 1st January 2020.
	* It should be an unsigned 32 bit integer.
	*/

	/*
	* nsec
	* 30 bits
	*
	* The nanosecond field is the specific number of nanoseconds.
	*/

	/*
	* ver
	* This is the implementation of a rejected UUID version 7.
	* 0     0     1     0
	*/
	// ver :=

	/*
	* var
	* 1     0     x
	*/
	// var :=

	/*
	* seq
	*/
	// seq :=

	/*
	* rand
	*/
	// rand :=

	/*
	* result
	*/
	// build result
	return 'v2 to be implemented'
}

pub fn parse_v2() {
}
