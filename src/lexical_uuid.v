module luuid

import rand
import time
import encoding.hex
import sync

const luuid_length = 32
const hyphen_indexes = [8, 13, 18, 23]
const luuid_length_with_hyphens = luuid_length + hyphen_indexes.len

const mask_2_bits = u8(0b11)
const mask_4_bits = u8(0b1111)
const mask_6_bits = u8(0b11_1111)
const mask_8_bits = u8(0b1111_1111)

pub struct Generator {
mut:
	current_ts time.Time
	counter    u8
	mutex      sync.Mutex
}

// new_generator is the factory function that returns a new Generator.
// Always prefer utilizing the factory function.
pub fn new_generator() &Generator {
	return &Generator{
		current_ts: time.utc()
		counter: 0
	}
}

// verify_ts potentially modifies generator fields, it must be invoked before using generator fields
// during the generation process.
fn (mut gen Generator) verify_ts(ts time.Time) {
	// detect anomaly: hang generation, then continue
	// TODO handle large anomaly without waiting long
	if ts < gen.current_ts {
		// Sleep for the difference between ts and gen.current_ts
		time.sleep(gen.current_ts - ts)
		gen.current_ts = ts
		gen.counter = 0
		return
	}

	// handle generation in same nanosecond
	if ts == gen.current_ts {
		// prevent overflow: freeze counter and wait for timestamp to advance
		if gen.counter == 255 {
			// Sleep for a small duration to ensure the clock increments
			time.sleep(1 * time.nanosecond)
			gen.current_ts = ts.add(1 * time.nanosecond)
			gen.counter = 0
			return
		}
		gen.counter++
		return
	}

	gen.current_ts = ts
	gen.counter = 0
	return
}

pub fn remove_hyphens(id string) string {
	return id.replace('-', '')
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

fn new_random_array() []u8 {
	mut res := []u8{}
	// fill array with random data
	for i := 0; i < 16; i++ {
		random_u8 := u8(rand.intn(256) or { panic(err) }) // should never panic
		res << random_u8
	}
	return res
}

/*
*
* Version 1
*
*/

pub fn (mut gen Generator) v1() !string {
	gen.mutex.@lock()
	defer {
		gen.mutex.unlock()
	}

	ts := time.utc()
	gen.verify_ts(ts)

	mut res := new_random_array()

	/*
	* unixts
	* 36 bits
	*
	* Seconds since 1st January 1970, can represent dates until the year 4147
	*/
	unixts := u64(gen.current_ts.unix())

	/*
	* nsec
	* 30 bits
	*/
	nsec := u32(gen.current_ts.nanosecond)

	/*
	* ver
	* 4 bits
	*
	* Version is set to 1 because it is the first implementation of the Lexical UUID.
	* 0     0     0     1
	*/
	ver := u8(0b0001)

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
	seq := gen.counter

	// insert the data in the array
	res[0] = u8(unixts >> 28)
	res[1] = u8((unixts >> 20) & luuid.mask_8_bits)
	res[2] = u8((unixts >> 12) & luuid.mask_8_bits)
	res[3] = u8((unixts >> 4) & luuid.mask_8_bits)
	res[4] = u8(((unixts & luuid.mask_4_bits) << 4) | ((nsec >> 26) & luuid.mask_4_bits))
	res[5] = u8((nsec >> 18) & luuid.mask_8_bits)
	res[6] = u8(((nsec >> 14) & luuid.mask_4_bits) | (ver << 4))
	res[7] = u8((nsec >> 6) & luuid.mask_8_bits)
	res[8] = u8(((nsec & luuid.mask_6_bits) << 2) | (seq >> 6))
	res[9] = u8((seq & luuid.mask_6_bits) << 2)

	new_luuid_without_hyphens := hex.encode(res)
	return add_hyphens(new_luuid_without_hyphens)!
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
fn verify(id string) ![]u8 {
	verify_luuid_length(id)!
	if id.len == luuid.luuid_length_with_hyphens {
		verify_hypens_amount(id)!
		verify_hypens_position(id)!
		luuid_without_hyphens := id.replace('-', '')
		return hex.decode(luuid_without_hyphens)!
	}

	verify_lacks_hyphens(id)!
	return hex.decode(id)!
}

struct Luuid {
	timestamp time.Time
	version   int
}

fn extract_seconds(binary_id []u8) i64 {
	mut res := u64(0)
	for i := 0; i < 5; i++ {
		res = (res << 8) | binary_id[i]
	}
	// discard the least significant 4 bits, as they are part of the nanosecond bits
	res = res >> 4
	cast_res := i64(res)
	return cast_res
}

fn extract_nanoseconds(binary_id []u8) int {
	mut res := u32(0)
	res = binary_id[4] & luuid.mask_4_bits

	for i := 5; i < 8; i++ {
		res = (res << 8) | binary_id[i]
	}

	res = (res << 2) | ((binary_id[8] >> 6) & luuid.mask_2_bits)

	cast_res := int(res)
	return cast_res
}

fn extract_timestamp(binary_id []u8) !time.Time {
	seconds := extract_seconds(binary_id)
	nanoseconds := extract_nanoseconds(binary_id)
	ts := time.unix_nanosecond(seconds, nanoseconds)
	return ts
}

pub fn parse(id string) !Luuid {
	parse_error_message := 'The ID is not a Luuid'
	bin := verify(id)!

	version := (bin[6] >> 4) & luuid.mask_4_bits
	if version == 1 {
		ts := extract_timestamp(bin) or { return error(parse_error_message) }
		return Luuid{
			timestamp: ts
			version: version
		}
	}

	if version == 2 {
		ts := extract_timestamp(bin) or { return error(parse_error_message) }
		return Luuid{
			timestamp: ts
			version: version
		}
	}

	return error(parse_error_message)
}

/*
*
* Version 2
*
*/

// v2 does not use a generator and does not contain monotonic counter bits.
pub fn v2() !string {
	mut res := new_random_array()

	ts := time.utc()

	unixts := u64(ts.unix())
	nsec := u32(ts.nanosecond)
	ver := u8(0b0010)

	// unixts 36 bits, nsec 12 bits, ver 4 bits, nsec 18 bits
	res[0] = u8(unixts >> 28)
	res[1] = u8((unixts >> 20) & luuid.mask_8_bits)
	res[2] = u8((unixts >> 12) & luuid.mask_8_bits)
	res[3] = u8((unixts >> 4) & luuid.mask_8_bits)
	res[4] = u8(((unixts & luuid.mask_4_bits) << 4) | ((nsec >> 26) & luuid.mask_4_bits))
	res[5] = u8((nsec >> 18) & luuid.mask_8_bits)
	res[6] = u8(((nsec >> 14) & luuid.mask_4_bits) | (ver << 4))
	res[7] = u8((nsec >> 6) & luuid.mask_8_bits)
	res[8] = (res[8] & luuid.mask_2_bits) | u8((nsec & luuid.mask_6_bits) << 2)

	new_luuid_without_hyphens := hex.encode(res)
	return add_hyphens(new_luuid_without_hyphens)!
}
