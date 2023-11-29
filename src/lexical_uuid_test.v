module luuid

import rand

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
	// TODO parse
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
	verify(stripped_v4) or { assert true }

	mut g := new_generator()
	luuid_v1 := g.v1() or { panic(err) }
	verify(luuid_v1) or {
		assert false
		return
	}

	luuid_v2 := g.v2() or { panic(err) }
	verify(luuid_v2) or {
		assert false
		return
	}

	luuid_v3 := v3() or { panic(err) }
	verify(luuid_v3) or {
		assert false
		return
	}
}
