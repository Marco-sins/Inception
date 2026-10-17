COMPOSE := docker compose
COMPOSE_FILE := -f ./srcs/docker-compose.yml

all:
	@$(COMPOSE) $(COMPOSE_FILE) up -d --build

down:
	@$(COMPOSE) $(COMPOSE_FILE) down

clean:
	@$(COMPOSE) $(COMPOSE_FILE) down -v --rmi local
	@sudo rm -rf /home/mmembril/data/mysql/* /home/mmembril/data/wordpress/*

.PHONY: all down clean