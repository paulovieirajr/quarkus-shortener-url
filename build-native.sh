#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_native_binary() {
    if ls target/*-runner 1> /dev/null 2>&1; then
        echo -e "${GREEN}✅ Binário nativo encontrado: $(ls target/*-runner)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Binário nativo não encontrado${NC}"
        return 1
    fi
}

check_docker_image() {
    if docker image inspect paulovieirajr/shortener-url-native:latest >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Imagem Docker encontrada: paulovieirajr/shortener-url-native:latest${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Imagem Docker não encontrada${NC}"
        return 1
    fi
}

RESTART=false
SKIP_NATIVE=false
SKIP_DOCKER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --restart|-f)
            RESTART=true
            shift
            ;;
        --skip-native)
            SKIP_NATIVE=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --help|-h)
            echo -e "${BLUE}📖 Uso do script:${NC}"
            echo "  ./build.sh                 # Compila o app para binario nativo e builda imagem Docker"
            echo "  ./build.sh --restart       # Força rebuild completo"
            echo "  ./build.sh --skip-native   # Pula compilação nativa"
            echo "  ./build.sh --skip-docker   # Pula build da imagem Docker"
            echo "  ./build.sh --help          # Mostra esta ajuda"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Argumento desconhecido: $1${NC}"
            echo "Use --help para ver opções disponíveis"
            exit 1
            ;;
    esac
done

if [[ "$RESTART" == false && "$SKIP_NATIVE" == false && "$SKIP_DOCKER" == false ]]; then
    echo -e "${BLUE}🔍 Verificando estados atuais...${NC}"
    if docker ps -q --filter "name=app" --filter "name=mongo-db" --filter "name=mongo-express" | grep -q .; then
        echo -e "\n${GREEN}✅ Containers já estão rodando!${NC}"
        echo -e "\n${BLUE}🔌 Listando containers...\n${NC}"
        docker ps --filter "name=app" --filter "name=mongo-db" --filter "name=mongo-express"
        echo -e ""
        echo -e "${YELLOW}⚠️  Para reiniciar os containers, use: ./build.sh --restart${NC}"
        exit 0
    fi
fi

if [ "$SKIP_NATIVE" = true ]; then
    echo -e "${YELLOW}⏭️  Pulando compilação nativa (--skip-native)${NC}"
elif [ "$RESTART" = true ] || ! check_native_binary; then
    echo -e "${BLUE}🔧 Compilando binário nativo...${NC}"
    ./mvnw clean package -Dnative -DskipTests \
        -Dquarkus.native.container-build=true \
        -Dquarkus.native.builder-image=quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-21
    echo -e "${GREEN}✅ Binário nativo compilado com sucesso!${NC}"
else
    echo -e "${GREEN}⏭️  Binário nativo já existe, pulando compilação${NC}"
fi

if [ "$SKIP_DOCKER" = true ]; then
    echo -e "${YELLOW}⏭️  Pulando build da imagem Docker (--skip-docker)${NC}"
elif [ "$RESTART" = true ] || ! check_docker_image; then
    echo -e "${BLUE}🐳 Buildando imagem Docker...${NC}"
    docker build -f src/main/docker/Dockerfile.native-micro -t paulovieirajr/shortener-url-native:latest .
    echo -e "${GREEN}✅ Imagem Docker criada com sucesso!${NC}"
else
    echo -e "${GREEN}⏭️  Imagem Docker já existe, pulando build${NC}"
fi

echo -e "${BLUE}🧹 Limpando containers anteriores...${NC}"
docker-compose -f compose.yml down --remove-orphans 2>/dev/null || true

echo -e "${BLUE}🚀 Iniciando containers...${NC}"
docker-compose -f compose.yml up app mongo-db mongo-express -d

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
echo -e "   - Health Check: ${YELLOW}http://localhost:8080/q/health${NC}"
echo -e "   - MongoDB Express: ${YELLOW}http://localhost:8081${NC}"
echo ""
echo -e "${RED}⚠️ Quarkus Dev UI e Swagger UI não estão disponíveis no modo nativo!${NC}"
echo ""
echo -e "${BLUE}🔑 Credenciais MongoDB Express:${NC}"
echo -e "   - Usuário: ${YELLOW}admin${NC}"
echo -e "   - Senha: ${YELLOW}admin${NC}"
echo ""
echo -e "${BLUE}📊 Comandos úteis:${NC}"
echo -e "   - Ver logs: ${YELLOW}docker-compose -f compose.yml logs -f app${NC}"
echo -e "   - Parar tudo: ${YELLOW}docker-compose -f compose.yml down${NC}"
echo -e "   - Restart DB: ${YELLOW}docker-compose -f compose.yml restart mongo-db mongo-express${NC}"
echo -e "   - Parar e remover containers: ${YELLOW}docker-compose -f compose.yml down --volumes --remove-orphans${NC}"