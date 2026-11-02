SHELL := /bin/bash
.DEFAULT_GOAL := help

GODOT ?= $(shell bash tools/find-godot.sh 2>/dev/null)
PROJECT_DIR := $(CURDIR)
PRESET ?= Linux
EXPORT_PATH ?=
ARGS ?=
INSTALL_ARGS ?=

.PHONY: help install doctor import run run-headless run-bg stop test check build build-windows export-check clean clean-all install-templates generate-ambience

help:
	@echo "Innsmouth Protocol · operaciones"
	@echo ""
	@echo "  make install          Instala/prepara Godot, importa el proyecto y ejecuta las pruebas."
	@echo "  make install INSTALL_ARGS=--templates  También instala plantillas de exportación (~1,2 GB)."
	@echo "  make doctor            Comprueba Godot, proyecto y plantillas de exportación."
	@echo "  make import            Fuerza el escaneo/importación de recursos en Godot."
	@echo "  make run               Abre el juego con ventana."
	@echo "  make run-headless      Ejecuta el juego sin ventana (útil para CI)."
	@echo "  make run-bg            Ejecuta en segundo plano con PID y log en .run/."
	@echo "  make stop              Detiene la instancia lanzada con make run-bg."
	@echo "  make test              Ejecuta la prueba de humo headless."
	@echo "  make check             Importa el proyecto y ejecuta la prueba de humo."
	@echo "  make build             Exporta la versión Linux a build/linux/."
	@echo "  make build-windows     Exporta la versión Windows a build/windows/."
	@echo "  make export-check      Valida preset y plantillas sin exportar."
	@echo "  make install-templates Descarga las plantillas oficiales (~1,2 GB)."
	@echo "  make generate-ambience Regenera el audio ambiental original con Python 3."
	@echo "  make clean             Borra caché .godot/ y temporales .run/."
	@echo "  make clean-all         Además borra los artefactos de build/."
	@echo ""
	@echo "Variables: GODOT=/ruta/a/godot PRESET=Linux EXPORT_PATH=... ARGS='--editor'"

install:
	@GODOT="$(GODOT)" bash install.sh $(INSTALL_ARGS)

doctor:
	@GODOT="$(GODOT)" bash tools/doctor.sh

import:
	@GODOT="$(GODOT)" bash tools/godot.sh --headless --editor --quit --path "$(PROJECT_DIR)"

run:
	@GODOT="$(GODOT)" bash tools/run.sh $(ARGS)

run-headless:
	@HEADLESS=1 GODOT="$(GODOT)" bash tools/run.sh $(ARGS)

run-bg:
	@GODOT="$(GODOT)" bash tools/run-bg.sh $(ARGS)

stop:
	@bash tools/stop.sh

test:
	@if [[ ! -f "$(PROJECT_DIR)/.godot/global_script_class_cache.cfg" ]]; then \
		echo "Caché de clases ausente; importando recursos..."; \
		GODOT="$(GODOT)" bash tools/godot.sh --headless --editor --quit --path "$(PROJECT_DIR)" >/dev/null; \
	fi
	@GODOT="$(GODOT)" bash tools/godot.sh --headless --path "$(PROJECT_DIR)" res://tests/SmokeTest.tscn

check: import test

build:
	@GODOT="$(GODOT)" PRESET="$(PRESET)" EXPORT_PATH="$(EXPORT_PATH)" bash tools/build.sh

build-windows:
	@GODOT="$(GODOT)" PRESET="Windows Desktop" EXPORT_PATH="build/windows/innsmouth-protocol.exe" bash tools/build.sh

export-check:
	@GODOT="$(GODOT)" PRESET="$(PRESET)" EXPORT_PATH="$(EXPORT_PATH)" bash tools/build.sh --check

install-templates:
	@GODOT="$(GODOT)" bash tools/install-templates.sh

generate-ambience:
	@python3 tools/generate-ambience.py

clean:
	@bash tools/clean.sh

clean-all:
	@bash tools/clean.sh --all
