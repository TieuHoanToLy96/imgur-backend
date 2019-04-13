up:
	docker-compose up -d
stop:
	docker-compose stop
	docker rm -f $(docker ps -a | grep imgur_app | awk '{print $1}') || echo "\n\n >bash stoped before\n\n"
app:
	docker rm -f imgur_app; docker-compose run --name imgur_app --use-aliases --service-ports phoenix
bash:
	docker-compose run phoenix bash
prod:
	docker-compose run \
		-e MIX_ENV=$MIX_ENV \
		-e NODE_ENV=$NODE_ENV \
		-e IMGUR_HOSTNAME=$IMGUR_HOSTNAME \
		--name imgur_app --rm \
	  -p 8000:4000 \
	  phoenix iex -S mix phx.server
format:
	mix format mix.exs “lib/**/*.{ex,exs}”
