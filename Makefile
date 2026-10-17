all:
	@docker-compose -f ./srcs/docker-compose.yml up -d --build

down:
	@docker-compose -f ./srcs/docker-compose.yml down

clean:
	@rm -fr /home/mmembril/data/mysql/*
	@rm -fr /home/mmembril/data/wordpress/*
	-@docker stop $$(docker ps -qa) 2>/dev/null
	-@docker rm $$(docker ops -qa) 2>/dev/null
	-@docker rmi $$(docker images -qa) 2>/dev/null
	-@docker volume rm $$(docker volume ls -q) 2>/dev/null
	-@docker network rm mmembrilnet 2>/dev/null

.PHONY: all down clean