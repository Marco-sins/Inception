COMPOSE := $(shell if command -v docker-compose >/dev/null 2>&1; then echo docker-compose; else echo docker compose; fi)
COMPOSE_FILE := -f ./srcs/docker-compose.yml

all:
	@$(COMPOSE) $(COMPOSE_FILE) up -d --build

down:
	@$(COMPOSE) $(COMPOSE_FILE) down

clean:
	@$(COMPOSE) $(COMPOSE_FILE) down -v --rmi local
	@rm -rf /home/mmembril/data/mysql/* /home/mmembril/data/wordpress/*

.PHONY: all down clean