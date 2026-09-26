.DEFAULT_GOAL := help
SHELL := /bin/bash
SERVICES := kruzetech-auth kruzetech-task kruzetech-gateway

help: ## Liệt kê lệnh
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

env: ## Tạo .env cho từng service từ .env.example (JWT_SECRET auth = task, tự sinh ngẫu nhiên)
	@S=$$(openssl rand -hex 32); R=$$(openssl rand -hex 32); \
	for s in $(SERVICES); do [ -f services/$$s/.env ] || cp services/$$s/.env.example services/$$s/.env; done; \
	sed -i "s/^JWT_SECRET=.*/JWT_SECRET=$$S/" services/kruzetech-auth/.env services/kruzetech-task/.env; \
	sed -i "s/^JWT_REFRESH_SECRET=.*/JWT_REFRESH_SECRET=$$R/" services/kruzetech-auth/.env

infra: ## Bật Postgres + Redis
	docker compose up -d postgres redis

up: ## Build và chạy toàn bộ (infra + 3 service) bằng Docker
	docker compose --profile app up --build -d

down: ## Tắt tất cả
	docker compose --profile app down

run-auth: ## Chạy kruzetech-auth (:3000)
	cd services/kruzetech-auth && ./gradlew bootRun

run-task: ## Chạy kruzetech-task (:3010)
	cd services/kruzetech-task && ./gradlew bootRun

run-gateway: ## Chạy kruzetech-gateway (:8080)
	cd services/kruzetech-gateway && ./gradlew bootRun

test: ## Test cả 3 service (H2, không cần Docker)
	@for s in $(SERVICES); do (cd services/$$s && ./gradlew test) || exit 1; done

build: ## Build jar cả 3 service
	@for s in $(SERVICES); do (cd services/$$s && ./gradlew bootJar) || exit 1; done
