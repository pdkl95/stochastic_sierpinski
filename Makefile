top_srcdir ?= .
srcdir     ?= $(top_srcdir)
builddir   ?= $(top_srcdir)

#
# config
#

COFFEE ?= coffee
COFFEE_OPTIONS ?= --no-header --compile

RM ?= rm -f
M4 ?= m4

M4_OPTIONS ?= -I$(srcdir) -I$(builddir)

#
# build deps
#

MAIN_TARGET = $(builddir)/stochastic_sierpinski.html
MAIN_TARGET_SRC = $(srcdir)/page.html.m4
MAIN_TARGET_DEPS = \
	$(builddir)/main.js \
	$(srcdir)/basic.css \
	$(srcdir)/style.css

COFFEE_SRC = $(wildcard $(srcdir)/*.coffee)

JS_TARGETS = $(patsubst $(srcdir)/%.coffee,$(builddir)/%.js,$(COFFEE_SRC))

TARGETS = \
	$(MAIN_TARGET) \
	$(JS_TARGETS)


#
# build instructions
#
all: build
build: $(TARGETS)

$(builddir)/%.js: $(srcdir)/%.coffee
	$(COFFEE) $(COFFEE_OPTIONS) $< > $@

$(MAIN_TARGET): $(MAIN_TARGET_DEPS)
	$(M4) $(M4OPTS) $(MAIN_TARGET_SRC) >$@

clean:
	$(RM) $(TARGETS)

.PHONY: all build clean
