.PHONY: all build run restart kill push install-login uninstall-login status-login clean help

APP_NAME = CalendarBar
APP_BUNDLE = $(APP_NAME).app
MSG ?= Update $(APP_NAME)

all: build

build:
	@./build.sh

run: build
	@open $(APP_BUNDLE)

kill:
	@pkill -x $(APP_NAME) 2>/dev/null || true

restart: kill build
	@sleep 0.5
	@open $(APP_BUNDLE)

push:
	@git add -A
	@git commit -m "$(MSG)" || true
	@git push origin main

install-login:
	@osascript -e 'tell application "System Events" to make login item at end with properties {name:"$(APP_NAME)", path:"$(CURDIR)/$(APP_BUNDLE)", hidden:false}'
	@echo "✅ Registered $(APP_NAME) to launch on login."

uninstall-login:
	@osascript -e 'tell application "System Events" to delete (every login item whose name is "$(APP_NAME)")'
	@echo "✅ Removed $(APP_NAME) from login items."

status-login:
	@osascript -e 'tell application "System Events" to return exists (login item "$(APP_NAME)")' | grep -q "true" \
		&& echo "✅ $(APP_NAME) is configured to launch on login." \
		|| echo "❌ $(APP_NAME) is NOT configured to launch on login."

clean:
	@rm -rf $(APP_BUNDLE)
