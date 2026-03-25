ROOT_DIR = /home/isidro/Datos/nasm
PROJECT_SRC = proyectos/archivos/lib_file/main.asm

all:
	@$(MAKE) --no-print-directory -C $(ROOT_DIR) SRC=$(PROJECT_SRC)

clean:
	@$(MAKE) --no-print-directory -C $(ROOT_DIR) clean

run: all
	@echo "--- EJECUTANDO ---"
	@$(ROOT_DIR)/bin/main
