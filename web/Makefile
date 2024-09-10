# Makefile

# Build the frontend project and ensure the Docker image is up-to-date
frontend:
	pnpm i && pnpm build

server:
	docker compose build

deploy:
	docker-compose up -d

stop:
	docker-compose down