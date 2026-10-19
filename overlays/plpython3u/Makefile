# PL/Python as a PGXS extension, built from PostgreSQL's own source tree
# (src/pl/plpython) against an *installed* PostgreSQL that was configured
# without --with-python, such as Homebrew's postgresql@18. Building against the
# installed server headers (not this tree's) is what makes the module match
# the server that loads it exactly.
#
# Replaces the in-tree Makefile, which needs the whole tree configured. The
# sources, control file and SQL are PostgreSQL's, unmodified.
#
#   PYTHON  the interpreter to embed; its python3.x-config gives the flags.
#           The module links that Python's library by absolute path.

PYTHON ?= python3

MODULE_big = plpython3
OBJS = \
	plpy_cursorobject.o \
	plpy_elog.o \
	plpy_exec.o \
	plpy_main.o \
	plpy_planobject.o \
	plpy_plpymodule.o \
	plpy_procedure.o \
	plpy_resultobject.o \
	plpy_spi.o \
	plpy_subxactobject.o \
	plpy_typeio.o \
	plpy_util.o
PGFILEDESC = "PL/Python - procedural language"

EXTENSION = plpython3u
DATA = plpython3u--1.0.sql

PG_CPPFLAGS = -I. $(shell $(PYTHON)-config --includes)
# As upstream: plus gettext when PostgreSQL was built with NLS (Homebrew's is),
# for PL/Python's translated messages. Recursive (=), so $(LIBS) is read from
# PGXS's Makefile.global when used; set before the include, which appends the
# server link (-bundle_loader on macOS) to it.
SHLIB_LINK = $(shell $(PYTHON)-config --ldflags --embed) $(filter -lintl,$(LIBS))
EXTRA_CLEAN = spiexceptions.h

PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# Generated from the error codes of this source tree's PostgreSQL version.
plpy_plpymodule.o: spiexceptions.h
spiexceptions.h: ../../backend/utils/errcodes.txt generate-spiexceptions.pl
	perl generate-spiexceptions.pl $< > $@
