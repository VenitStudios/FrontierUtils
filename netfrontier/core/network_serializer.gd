extends Node


func serialize(data: Variant) -> PackedByteArray:
	var type: int = typeof(data)
	match type:
		TYPE_VECTOR3: return serialize_vector3(data)
		TYPE_VECTOR3I: return serialize_vector3i(data)
		TYPE_BOOL: return serialize_boolean(data)
		TYPE_INT: return serialize_integer(data)
	return []

func deserialize(data: PackedByteArray) -> Variant:
	var type: int = data[0]
	match type:
		TYPE_VECTOR3: return deserialize_vector3(data)
		TYPE_VECTOR3I: return deserialize_vector3i(data)
		TYPE_BOOL: return deserialize_boolean(data)
		TYPE_INT: return deserialize_integer(data)
	return null

func serialize_vector3(vector: Vector3) -> PackedByteArray:
	var pba: PackedByteArray
	pba.resize(1 + 3 * 4) # 1 byte for type + 3 half floats
	pba.encode_s8(0, TYPE_VECTOR3)
	for i in 3: pba.encode_float(1 + i*4, vector[i])
	return pba

func deserialize_vector3(input: PackedByteArray) -> Vector3:
	var output = Vector3()
	for i in 3: output[i] = input.decode_float(1 + i*4)
	return output

func serialize_vector3i(vector: Vector3i) -> PackedByteArray:
	var pba: PackedByteArray
	pba.resize(1 + 3 * 4) # 1 byte for type + 3 shorts
	pba.encode_s8(0, TYPE_VECTOR3I)
	for i in 3: pba.encode_s32(1 + i*4, vector[i])
	return pba

func deserialize_vector3i(input: PackedByteArray) -> Vector3i:
	var output = Vector3i()
	for i in 3: output[i] = input.decode_s32(1 + i*4)
	return output


func serialize_boolean(boolean: bool) -> PackedByteArray:
	var pba: PackedByteArray = [0,0]
	pba.encode_s8(0, TYPE_BOOL)
	pba.encode_s8(1, int(boolean))
	return pba

func deserialize_boolean(input: PackedByteArray) -> bool:
	return bool(input.decode_s8(1))


func serialize_integer(integer: int) -> PackedByteArray:
	var pba: PackedByteArray
	pba.resize(3)
	pba.encode_s8(0, TYPE_INT)
	pba.encode_s16(1, integer)
	return pba

func deserialize_integer(input: PackedByteArray) -> int:
	return input.decode_s16(1)
