module luuid

fn test_v1() {
	mut g := new_generator()
	res := g.v1()
	assert res.len == 36
}

fn test_v2() {
	res := v2()
	assert res.len == 36
}

fn test_parse_v1() {
	mut g := new_generator()
	luuid_v1 := g.v1()
	parsed_unmodified := parse(luuid_v1)!
	assert parsed_unmodified.version == 1
}

fn test_parse_v2() {
	luuid_v2 := v2()
	parsed_unmodified := parse(luuid_v2)!
	assert parsed_unmodified.version == 2
}

fn test_remove_hyphens() {
	luuid_v2 := v2()
	luuid_without_hyphens := '${luuid_v2[..8]}${luuid_v2[9..13]}${luuid_v2[14..18]}${luuid_v2[19..23]}${luuid_v2[24..]}'
	res := remove_hyphens(luuid_v2)
	assert res == luuid_without_hyphens
}

fn test_to_bytes() {
	mut g := new_generator()
	v_1 := g.v1()
	v_2 := v2()
	v_1_bytes := to_bytes(v_1)!
	v_2_bytes := to_bytes(v_2)!
}
