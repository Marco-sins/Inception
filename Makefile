ifeq ($(shell docker compose version >/dev/null 2>&1; echo $$?),0)
COMPOSE := docker compose
else ifneq ($(shell command -v docker-compose 2>/dev/null),)
COMPOSE := docker-compose
else
$(error Docker Compose is not installed. Install the Docker Compose plugin or docker-compose)
endif

COMPOSE := $(COMPOSE) -f srcs/docker-compose.yml
DATA_DIR := /home/mmembril/data

all: prepare
	-$(COMPOSE) down --remove-orphans
	$(COMPOSE) up -d --build

prepare:
	@mkdir -p $(DATA_DIR)/mysql $(DATA_DIR)/wordpress
	@test -f srcs/.env || cp srcs/.env.example srcs/.env

up: all

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs --tail=100

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down --rmi local --volumes
	rm -rf $(DATA_DIR)

fclean: clean

re: down all

.PHONY: all prepare up down logs ps clean fclean re
