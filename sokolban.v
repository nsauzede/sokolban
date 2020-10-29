import time
import sokol
import sokol.sapp
import sokol.gfx

const (
	gfx_ver = gfx.version
)

const (
	c_empty   = ` `
	c_store   = `.`
	c_stored  = `*`
	c_crate   = `$`
	c_player  = `@`
	c_splayer = `+`
	c_wall    = `#`
)

struct State {
mut:
	map    [][]rune = [
	[`#`, `#`, `#`, `#`, `#`, `#`],
	[`#`, ` `, ` `, ` `, ` `, `#`],
	[`#`, `@`, `$`, ` `, ` `, `#`],
	[`#`, ` `, ` `, `.`, ` `, `#`],
	[`#`, `#`, `#`, `#`, `#`, `#`],
]
	w      int
	h      int
	stored int
	crates int
	px     int
	py     int
	dirty  bool = true
}

fn (s State) can_move(x int, y int) bool {
	if x < s.w && y < s.h {
		e := s.map[y][x]
		if e == c_empty || e == c_store {
			return true
		}
	}
	return false
}

fn (mut s State) try_move(dx int, dy int) bool {
	mut do_it := false
	x := s.px + dx
	y := s.py + dy
	if s.map[y][x] == c_crate || s.map[y][x] == c_stored {
		to_x := x + dx
		to_y := y + dy
		if s.can_move(to_x, to_y) {
			do_it = true
			s.map[y][x] = match s.map[y][x] {
				c_stored { c_store }
				else { c_empty }
			}
			s.map[to_y][to_x] = match s.map[to_y][to_x] {
				c_store { c_stored }
				else { c_crate }
			}
		}
	} else {
		do_it = s.can_move(x, y)
	}
	if do_it {
		s.map[s.py][s.px] = match s.map[s.py][s.px] {
			c_splayer { c_store }
			else { c_empty }
		}
		s.px = x
		s.py = y
		s.map[s.py][s.px] = match s.map[s.py][s.px] {
			c_store { c_splayer }
			else { c_player }
		}
	}
	s.dirty = do_it
	return do_it
}

fn main() {
	mut s := State{}
	s.h = s.map.len
	s.w = s.map[0].len
	desc := C.sapp_desc{
		width: 100
		height: 100
		frame_userdata_cb: frame
		event_userdata_cb: event
		user_data: &s
	}
	sapp.run(&desc)
}

fn frame(user_data voidptr) {
	mut s := &State(user_data)
	if s.dirty {
		s.stored = 0
		s.crates = 0
		s.dirty = false
		print('\x1b[2J')
		print('\x1b[H')
		for y in 0 .. s.h {
			for x in 0 .. s.w {
				match s.map[y][x] {
					`@` {
						s.px = x
						s.py = y
					}
					`+` {
						s.px = x
						s.py = y
					}
					`$` {
						s.crates++
					}
					`*` {
						s.crates++
						s.stored++
					}
					else {}
				}
				print(s.map[y][x])
			}
			println('')
		}
		println('stored=$s.stored crates=$s.crates')
		if s.stored == s.crates {
			println('YOU WIN!')
		}
	}
	// sleep
	time.sleep_ms(1000 / 60)
}

fn event(ev &C.sapp_event, user_data voidptr) {
	mut s := &State(user_data)
	match ev.@type {
		.key_down { match ev.key_code {
				.escape {
					C.sapp_request_quit()
				}
				.up {
					s.try_move(0, -1)
				}
				.down {
					s.try_move(0, 1)
				}
				.left {
					s.try_move(-1, 0)
				}
				.right {
					s.try_move(1, 0)
				}
				else {
					println('key=$ev.key_code')
					s.dirty = true
				}
			} }
		else {}
	}
}
