module luuid

fn test_v1() {
	mut g := new_generator()
	v1 := g.v1() or { panic(err) }
}

// TODO validate

fn test_v2() {
	mut g := new_generator()
	v2 := g.v2() or { panic(err) }
}

// TODO validate

fn test_v3() {
	res := v3() or { panic(err) }
	println(res)
}

// TODO validate
