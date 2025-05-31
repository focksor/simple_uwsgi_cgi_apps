.PHONY: all build run test exit clean

UWSGI_PORT = 8000
UWSGI_PID = $(PWD)/uwsgi.pid
UWSGI_LOG = $(PWD)/uwsgi.log

UWSGI_SOURCE = ./uwsgi
UWSGI_BIN = $(UWSGI_SOURCE)/uwsgi
UWSGI_CGI_PLUGIN = $(UWSGI_SOURCE)/cgi_plugin.so

CGI_APPS = ./apps
CGI_C_APP = $(CGI_APPS)/hello.cgi

ALL_BINS = $(UWSGI_BIN) $(UWSGI_CGI_PLUGIN) $(CGI_C_APP)

all: test kill
	@echo "All things ok."

build: $(ALL_BINS)
	@echo "All built successfully."

run: kill $(UWSGI_PID)
	@echo "uWSGI is running on port $(UWSGI_PORT)."

kill:
	@if [ -f $(UWSGI_PID) ]; then \
		kill $(shell cat $(UWSGI_PID)); \
		rm -f $(UWSGI_PID); \
		echo "uWSGI process killed."; \
	else \
		echo "No uWSGI process running."; \
	fi
	@rm -f *.log

test: $(UWSGI_PID)
	@echo "Testing uWSGI CGI application..."
	
	@echo "Testing C application on http://localhost:$(UWSGI_PORT)/hello.cgi"
	@curl -s http://localhost:$(UWSGI_PORT)/hello.cgi | grep "Hello, CGI world!" && echo "Test passed!" || { echo "Test failed!"; exit 1; }
	
	@echo "Testing Bash application on http://localhost:$(UWSGI_PORT)/bash.cgi"
	@curl -s http://localhost:$(UWSGI_PORT)/bash.cgi | grep "Hello, CGI Bash Script!" && echo "Test passed!" || { echo "Test failed!"; exit 1; }
	
	@echo "All tests ok."

clean:
	rm *.log
	rm -rf $(UWSGI_SOURCE)
	rm -f $(CGI_C_APP)

$(UWSGI_SOURCE):
	git clone git@github.com:unbit/uwsgi.git -b uwsgi-2.0 --depth=1

$(UWSGI_BIN): $(UWSGI_SOURCE)
	cd $(UWSGI_SOURCE) && make PROFILE=cgi
	@echo "uWSGI built successfully."

$(UWSGI_CGI_PLUGIN): $(UWSGI)
	cd $(UWSGI_SOURCE) && python uwsgiconfig.py --plugin plugins/cgi
	@echo "uWSGI CGI plugin built successfully."

$(CGI_C_APP): hello.c
	gcc -o $(CGI_C_APP) hello.c
	@echo "CGI C-application built successfully."

$(UWSGI_PID): $(ALL_BINS)
	$(UWSGI_BIN) --plugin-dir $(UWSGI_SOURCE) --plugin cgi --cgi $(CGI_APPS) \
		--http-socket :$(UWSGI_PORT) --http-socket-modifier1 9 \
		--daemonize $(UWSGI_LOG) --vacuum --pidfile $(UWSGI_PID)

