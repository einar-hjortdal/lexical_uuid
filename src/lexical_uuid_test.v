module luuid

import rand

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

fn test_parse_v1() {
	mut g := new_generator()
	luuid_v1 := g.v1() or { panic(err) }
	parsed_unmodified := parse(luuid_v1) or { panic(err) }
	assert parsed_unmodified.version == 1
}

fn test_parse_v2() {
	luuid_v2 := v2() or { panic(err) }
	parsed_unmodified := parse(luuid_v2) or { panic(err) }
	assert parsed_unmodified.version == 2
}

fn test_remove_hyphens() {
	luuid_v2 := v2()!
	luuid_without_hyphens := '${luuid_v2[..8]}${luuid_v2[9..13]}${luuid_v2[14..18]}${luuid_v2[19..23]}${luuid_v2[24..]}'
	res := remove_hyphens(luuid_v2)
	assert res == luuid_without_hyphens
}
