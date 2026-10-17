DOCKER := $(shell if docker info >/dev/null 2>&1; then echo docker; else echo sudo docker; fi)
COMPOSE := $(DOCKER) compose
COMPOSE_FILE := -f ./srcs/docker-compose.yml
DATA_DIR := /home/mmembril/data

all:
	@test -f ./srcs/.env || cp ./srcs/env.txt ./srcs/.env
	@chmod 600 ./srcs/.env
	@sudo mkdir -p $(DATA_DIR)/mysql $(DATA_DIR)/wordpress
	@sudo sh -c 'grep -qxF "127.0.0.1 mmembril.42.fr" /etc/hosts || echo "127.0.0.1 mmembril.42.fr" >> /etc/hosts'
	@$(COMPOSE) $(COMPOSE_FILE) up -d --build

down:
	@$(COMPOSE) $(COMPOSE_FILE) down

clean:
	@$(COMPOSE) $(COMPOSE_FILE) down
	@$(COMPOSE) $(COMPOSE_FILE) down -v --rmi local
	@sudo rm -rf $(DATA_DIR)/mysql $(DATA_DIR)/wordpress

.PHONY: all down clean