module luuid

import strconv

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
	// TODO parse
}

fn test_v2() {
	mut g := new_generator()
	res := g.v2() or { panic(err) }
	// TODO parse
}

fn test_v3() {
	mut res := v3() or { panic(err) }
	println(res)
	bin := parse_v3(res) or { panic(err) }
	println(bin)
	res = bin_to_hex(bin) or { panic(err) }
	println(res)
}
