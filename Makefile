COMPOSE := docker compose -f srcs/docker-compose.yml
DATA_DIR := /home/mmembril/data

all: prepare
	$(COMPOSE) up -d --build

prepare:
	@sudo mkdir -p $(DATA_DIR)/mysql $(DATA_DIR)/wordpress
	@test -f srcs/.env || cp srcs/.env.example srcs/.env
	@grep -q "mmembril.42.fr" /etc/hosts || \
		echo "127.0.0.1 mmembril.42.fr" | sudo tee -a /etc/hosts >/dev/null

up: all

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down --rmi local --volumes
	sudo rm -rf $(DATA_DIR)

fclean: clean

re: down all

.PHONY: all prepare up down logs ps clean fclean re
