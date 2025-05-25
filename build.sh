#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_jar() {
    if ls target/*.jar 1> /dev/null 2>&1; then
        echo -e "${GREEN}✅ Jar encontrado: $(ls target/*.jar)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Jar não encontrado${NC}"
        return 1
    fi
}

check_docker_image() {
    if docker image inspect paulovieirajr/shortener-url:latest >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Imagem Docker encontrada: paulovieirajr/shortener-url:latest${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Imagem Docker não encontrada${NC}"
        return 1
    fi
}

RESTART=false
SKIP_IMAGE_APP=false
SKIP_DOCKER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --restart|-r)
            RESTART=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --help|-h)
            echo -e "${BLUE}📖 Uso do script:${NC}"
            echo "  ./build.sh                    # Compila jar e builda imagem Docker"
            echo "  ./build.sh --restart          # Força rebuild completo"
            echo "  ./build.sh --skip-docker      # Pula build da imagem Docker"
            echo "  ./build.sh --help             # Mostra esta ajuda"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Argumento desconhecido: $1${NC}"
            echo "Use --help para ver opções disponíveis"
            exit 1
            ;;
    esac
done

if [[ "$RESTART" == false && "$SKIP_IMAGE_APP" == false && "$SKIP_DOCKER" == false ]]; then
    echo -e "${BLUE}🔍 Verificando estados atuais...${NC}"
    if docker ps -q --filter "name=app-dev" --filter "name=mongo-db" --filter "name=mongo-express" | grep -q .; then
        echo -e "\n${GREEN}✅ Containers já estão rodando!${NC}"
        echo -e "\n${BLUE}🔌 Listando containers...\n${NC}"
        docker ps --filter "name=app-dev" --filter "name=mongo-db" --filter "name=mongo-express"
        echo -e ""
        echo -e "${YELLOW}⚠️  Para reiniciar os containers, use: ./build.sh --restart${NC}"
        exit 0
    fi
fi

if [ "$SKIP_DOCKER" = true ]; then
    echo -e "${YELLOW}⏭️  Pulando build da imagem Docker (--skip-docker)${NC}"
elif [ "$RESTART" = true ] || ! check_docker_image; then
    echo -e "${BLUE}🐳 Buildando imagem Docker...${NC}"
    docker build -f src/main/docker/Dockerfile.dev -t paulovieirajr/shortener-url:latest .
    echo -e "${GREEN}✅ Imagem Docker criada com sucesso!${NC}"
else
    echo -e "${GREEN}⏭️  Imagem Docker já existe, pulando build${NC}"
fi

echo -e "${BLUE}🧹 Limpando containers anteriores...${NC}"
docker-compose -f compose.yml down --remove-orphans 2>/dev/null || true

echo -e "${BLUE}🚀 Iniciando containers...${NC}"
docker-compose -f compose.yml up app-dev mongo-db mongo-express -d

echo -e "${BLUE}🔍 Verificando status dos containers...${NC}"
docker-compose -f compose.yml ps

echo -e "${BLUE}🏥 Verificando saúde da aplicação...${NC}"

MAX_RETRIES=30
RETRY_COUNT=0
HEALTHY=false
INITIAL_WAIT_LOGGED=false

while [ "$HEALTHY" = false ] && [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
    if curl -fs http://localhost:8080/q/health > /dev/null; then
        echo -e "\n✅ Aplicação está saudável!"
        HEALTHY=true
        break
    else
        if [ "$INITIAL_WAIT_LOGGED" = false ] && [ "$RETRY_COUNT" -ge 6 ]; then
            echo -e "\n⚠️ Aplicação não respondeu após 30 segundos, continuando a tentar..."
            INITIAL_WAIT_LOGGED=true
        else
            echo -n "."
        fi
        sleep 5
        RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
done

if [ "$HEALTHY" = false ]; then
    echo -e "\n⚠️ Aplicação não respondeu após todas as tentativas"
fi

echo ""
echo -e "${GREEN}🎉 Deploy concluído!${NC}"
echo ""
echo -e "${BLUE}🔌 Carregando extensões...${NC}"
sleep 8
echo ""
echo -e "${BLUE}🌐 Serviços disponíveis:${NC}"
echo -e "   - Aplicação: ${YELLOW}http://localhost:8080${NC}"
echo -e "   - Quarkus Dev UI: ${YELLOW}http://localhost:8080/q/dev-ui/extensions${NC}"
echo -e "   - Swagger UI: ${YELLOW}http://localhost:8080/q/swagger-ui${NC}"
echo -e "   - Health Check: ${YELLOW}http://localhost:8080/q/health${NC}"
echo -e "   - MongoDB Express: ${YELLOW}http://localhost:8081${NC}"
echo ""
echo -e "${BLUE}🔑 Credenciais MongoDB Express:${NC}"
echo -e "   - Usuário: ${YELLOW}admin${NC}"
echo -e "   - Senha: ${YELLOW}admin${NC}"
echo ""
echo -e "${BLUE}📊 Comandos úteis:${NC}"
echo -e "   - Ver logs: ${YELLOW}docker-compose -f compose.yml logs -f shortened-app-dev${NC}"
echo -e "   - Parar tudo: ${YELLOW}docker-compose -f compose.yml down${NC}"
echo -e "   - Restart DB: ${YELLOW}docker-compose -f compose.yml restart mongo-db mongo-express${NC}"
echo -e "   - Parar e remover containers: ${YELLOW}docker-compose -f compose.yml down --volumes --remove-orphans${NC}"