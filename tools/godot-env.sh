#!/usr/bin/env bash

resolve_godot() {
	local candidates=()
	local candidate version numbers major minor patch
	local selected="" selected_major=0 selected_minor=0 selected_patch=0

	if [[ -n "${GODOT:-}" ]]; then
		candidate="$GODOT"
		if [[ ! -x "$candidate" ]]; then
			candidate="$(command -v "$candidate" 2>/dev/null || true)"
		fi
		if [[ -z "$candidate" || ! -x "$candidate" ]]; then
			echo "ERROR: GODOT no apunta a un ejecutable: ${GODOT}" >&2
			return 1
		fi
		candidates+=("$candidate")
	else
		for command_name in godot4 godot; do
			candidate="$(command -v "$command_name" 2>/dev/null || true)"
			[[ -n "$candidate" ]] && candidates+=("$candidate")
		done

		candidate="$ROOT/.tools/godot/Godot_v4.7.2-stable_linux.x86_64"
		[[ -x "$candidate" ]] && candidates+=("$candidate")
	fi

	for candidate in "${candidates[@]}"; do
		[[ -x "$candidate" ]] || continue
		version="$("$candidate" --version 2>/dev/null)" || continue
		[[ "$version" == *".stable."* || "$version" == *.stable ]] || continue
		numbers="$(sed -nE 's/^([0-9]+)\.([0-9]+)(\.([0-9]+))?.*/\1 \2 \4/p' <<<"$version")"
		[[ -n "$numbers" ]] || continue
		read -r major minor patch <<<"$numbers"
		patch="${patch:-0}"
		if ((major < 4 || (major == 4 && minor < 7) || (major == 4 && minor == 7 && patch < 2))); then
			if [[ -n "${GODOT:-}" ]]; then
				echo "ERROR: se requiere Godot 4.7.2-stable o superior; encontrado: $version" >&2
				return 1
			fi
			continue
		fi

		if [[ -z "$selected" ]] || ((major > selected_major)) || \
			((major == selected_major && minor > selected_minor)) || \
			((major == selected_major && minor == selected_minor && patch > selected_patch)); then
			selected="$candidate"
			selected_major="$major"
			selected_minor="$minor"
			selected_patch="$patch"
		fi
	done

	if [[ -n "$selected" ]]; then
		printf '%s\n' "$selected"
		return 0
	fi
	return 1
}

require_godot() {
	local path
	if ! path="$(resolve_godot)"; then
		echo "ERROR: no se encontró un ejecutable compatible de Godot (4.7.2-stable o superior)." >&2
		echo "Instálalo con 'bash install.sh' o define GODOT=/ruta/a/godot." >&2
		return 1
	fi
	printf '%s\n' "$path"
}
