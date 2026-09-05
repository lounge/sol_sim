package main

import "core:fmt"
import png "core:image/png"
import gl "vendor:OpenGL"


TEX_DIR :: #directory + "tex/"


TEXTURE_FILES :: [?]struct {
	name, file: string,
} {
	{"Sun", "sun.png"},
	{"Mercury", "mercury.png"},
	{"Venus", "venus.png"},
	{"Earth", "earth.png"},
	{"Moon", "moon.png"},
	{"Mars", "mars.png"},
	{"Jupiter", "jupiter.png"},
	{"Io", "io.png"},
	{"Europa", "europa.png"},
	{"Ganymede", "ganymede.png"},
	{"Callisto", "callisto.png"},
	{"Saturn", "saturn.png"},
	{"Titan", "titan.png"},
	{"Rhea", "rhea.png"},
	{"Iapetus", "iapetus.png"},
	{"Uranus", "uranus.png"},
	{"Miranda", "miranda.png"},
	{"Titania", "titania.png"},
	{"Oberon", "oberon.png"},
	{"Neptune", "neptune.png"},
	{"Triton", "triton.png"},
	{"Pluto", "pluto.png"},
	{"Charon", "charon.png"},
}

Textures :: struct {
	fallback: u32,
	by_name:  map[string]u32,
}

texture_upload :: proc(width, height: i32, rgba: []byte) -> u32 {
	tex: u32

	gl.GenTextures(1, &tex)
	gl.BindTexture(gl.TEXTURE_2D, tex)
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.SRGB8_ALPHA8,
		width,
		height,
		0,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		raw_data(rgba),
	)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	return tex
}

texture_load :: proc(path: string) -> (tex: u32, ok: bool) {
	img, err := png.load_from_file(path, {.alpha_add_if_missing})
	if err != nil {
		fmt.printfln("Failed to load texture path: %s", path)

		return 0, false
	}

	defer png.destroy(img)
	assert(img.depth == 8 && img.channels == 4)
	return texture_upload(i32(img.width), i32(img.height), img.pixels.buf[:]), true

}

texture_create :: proc() -> Textures {
	white := [4]byte{255, 255, 255, 255}

	tex: Textures = {
		fallback = texture_upload(1, 1, white[:]),
	}

	for entry in TEXTURE_FILES {
		t, ok := texture_load(fmt.tprintf("%s%s", TEX_DIR, entry.file))
		if ok do tex.by_name[entry.name] = t
	}

	return tex

}

texture_lookup :: proc(textures: ^Textures, name: string) -> (tex: u32, textured: bool) {
	t, found := textures.by_name[name]
	if found do return t, true

	return textures.fallback, false
}
