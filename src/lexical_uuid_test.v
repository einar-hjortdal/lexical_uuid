module luuid

import rand
import strconv
import time

// bin_to_hex wraps build_result, returns a hex string given a binary string.
fn bin_to_hex(s string) !string {
	if s.len > 128 {
		return error('Binary string too long')
	}
	res := build_result(s) or { panic(err) }
	return res
}

fn test_v1() {
	mut g := new_generator()
	res := g.v1() or { panic(err) }
	assert res.len == 36
}

fn test_v2() {
	res := v2() or { panic(err) }
	assert res.len == 36
}

fn test_verify() {
	uuid_v4 := rand.uuid_v4()
	verify(uuid_v4) or {
		assert false
		return
	}

	stripped_v4 := uuid_v4.replace('-', '')
	verify(stripped_v4) or {
		assert false
		return
	}

	invalid_v4_longer := uuid_v4 + '0'
	verify(invalid_v4_longer) or { assert true }

	invalid_v4_shorter := uuid_v4[0..30]
	verify(invalid_v4_shorter) or { assert true }

	mut g := new_generator()
	luuid_v1 := g.v1() or { panic(err) }
	verify(luuid_v1) or {
		assert false
		return
	}

	luuid_v2 := v2() or { panic(err) }
	verify(luuid_v2) or {
		assert false
		return
	}
}

fn replace_luuid_timestamp(luuid_string string, ts time.Time) string {
	bin_id := verify(luuid_string) or { panic(err) }
	ts_seconds := ts.unix()
	unixts := pad_left_with_zeroes(strconv.format_uint(u64(ts.unix()), 2), 36) or { panic(err) }
	bin_nsec := strconv.format_uint(u64(ts.nanosecond), 2)
	nsec := pad_left_with_zeroes(bin_nsec, 30) or { panic(err) }
	nsec_1 := nsec[0..12]
	nsec_2 := nsec[12..]
	bin_res := '${unixts}${nsec_1}${bin_id[48..52]}${nsec_2}${bin_id[70..]}' // TODO currently replaces counter in v1
	res := build_result(bin_res) or { panic(err) }
	return res
}

fn test_parse_v1() {
	mut g := new_generator()
	luuid_v1 := g.v1() or { panic(err) }
	ts := time.utc()
	luuid_with_known_timestamp := replace_luuid_timestamp(luuid_v1, ts)
	parsed := parse(luuid_with_known_timestamp) or { panic(err) }
	assert parsed.timestamp.unix() == ts.unix()
	assert parsed.timestamp.nanosecond == ts.nanosecond
}

fn test_remove_hyphens() {
	luuid_v2 := v2()!
	luuid_without_hyphens := '${luuid_v2[..8]}${luuid_v2[9..13]}${luuid_v2[14..18]}${luuid_v2[19..23]}${luuid_v2[24..]}'
	res := remove_hyphens(luuid_v2)
	assert res == luuid_without_hyphens
}
