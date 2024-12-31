package ecs

import "base:runtime"
import "base:intrinsics"


// Copied and adjusted from here: https://github.com/odin-lang/Odin/blob/8fd318ea7a76b75974c834bb9d329958c81ce652/base/runtime/core_builtin.odin#L736
@private
// `resize_raw_dynamic_array` will try to resize memory of a passed raw dynamic array or map to the requested element count (setting the `len`, and possibly `cap`).
__resize_raw_dynamic_array :: #force_inline proc(array: rawptr, elem_size, elem_align: int, length: int, should_zero: bool, loc := #caller_location) -> runtime.Allocator_Error {
	if array == nil {
		return nil
	}
	a := (^runtime.Raw_Dynamic_Array)(array)

	if length <= a.cap {
		if should_zero && a.len < length {
			intrinsics.mem_zero(([^]byte)(a.data)[a.len*elem_size:], (length-a.len)*elem_size)
		}
		a.len = max(length, 0)
		return nil
	}

	if a.allocator.procedure == nil {
		a.allocator = context.allocator
	}
	assert(a.allocator.procedure != nil)

	old_size  := a.cap * elem_size
	new_size  := length * elem_size
	allocator := a.allocator

	new_data : []byte
	if should_zero {
		new_data = runtime.mem_resize(a.data, old_size, new_size, elem_align, allocator, loc) or_return
	} else {
		new_data = runtime.non_zero_mem_resize(a.data, old_size, new_size, elem_align, allocator, loc) or_return
	}
	if new_data == nil && new_size > 0 {
		return .Out_Of_Memory
	}

	a.data = raw_data(new_data)
	a.len = length
	a.cap = length
	return nil
}
