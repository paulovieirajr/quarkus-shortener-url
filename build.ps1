# build.ps1

$ErrorActionPreference = "Stop"

$RED = "`e[0;31m"
$GREEN = "`e[0;32m"
$YELLOW = "`e[1;33m"
$BLUE = "`e[0;34m"
$NC = "`e[0m"

function Check-Jar {
    $jar = Get-ChildItem -Path "target" -Filter "*.jar" -ErrorAction SilentlyContinue
    if ($jar) {
        Write-Host "${GREEN}✅ Jar encontrado: $($jar.FullName)${NC}"
        return $true
    } else {
        Write-Host "${YELLOW}⚠️  Jar não encontrado${NC}"
        return $false
    }
}

function Check-DockerImage {
    $exists = docker image inspect paulovieirajr/shortener-url:latest 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "${GREEN}✅ Imagem Docker encontrada: paulovieirajr/shortener-url:latest${NC}"
        return $true
    } else {
        Write-Host "${YELLOW}⚠️  Imagem Docker não encontrada${NC}"
        return $false
    }
}

$RESTART = $false
$SKIP_IMAGE_APP = $false
$SKIP_DOCKER = $false

foreach ($arg in $args) {
    switch ($arg) {
        "--restart" { $RESTART = $true }
        "-r"        { $RESTART = $true }
        "--skip-image-app" { $SKIP_IMAGE_APP = $true }
        "--skip-docker"    { $SKIP_DOCKER = $true }
        "--help" {
            Write-Host "${BLUE}📖 Uso do script:${NC}"
            Write-Host "  ./build.ps1                    # Compila jar e builda imagem Docker"
            Write-Host "  ./build.ps1 --restart          # Força rebuild completo"
            Write-Host "  ./build.ps1 --skip-image-app   # Pula compilação do jar da aplicação"
            Write-Host "  ./build.ps1 --skip-docker      # Pula build da imagem Docker"
            Write-Host "  ./build.ps1 --help             # Mostra esta ajuda"
            exit 0
        }
        default {
            Write-Host "${RED}❌ Argumento desconhecido: $arg${NC}"
            Write-Host "Use --help para ver opções disponíveis"
            exit 1
        }
    }
}

if (-not $RESTART -and -not $SKIP_IMAGE_APP -and -not $SKIP_DOCKER) {
    Write-Host "${BLUE}🔍 Verificando estados atuais...${NC}"
    $containers = docker ps -q --filter "name=app-dev" --filter "name=mongo-db" --filter "name=mongo-express"
    if ($containers) {
        Write-Host "`n${GREEN}✅ Containers já estão rodando!${NC}"
        Write-Host "`n${BLUE}🔌 Listando containers...${NC}"
        docker ps --filter "name=app-dev" --filter "name=mongo-db" --filter "name=mongo-express"
        Write-Host ""
        Write-Host "${YELLOW}⚠️  Para reiniciar os containers, use: ./build.ps1 --restart${NC}"
        exit 0
    }
}

if ($SKIP_DOCKER) {
    Write-Host "${YELLOW}⏭️  Pulando build da imagem Docker (--skip-docker)${NC}"
}
elseif ($RESTART -or -not (Check-DockerImage)) {
    Write-Host "${BLUE}🐳 Buildando imagem Docker...${NC}"
    docker build -f src/main/docker/Dockerfile.dev -t paulovieirajr/shortener-url:latest .
    Write-Host "${GREEN}✅ Imagem Docker criada com sucesso!${NC}"
}
else {
    Write-Host "${GREEN}⏭️  Imagem Docker já existe, pulando build${NC}"
}

Write-Host "${BLUE}🧹 Limpando containers anteriores caso existam...${NC}"
docker-compose -f compose.yml down --remove-orphans *>$null

Write-Host "${BLUE}🚀 Iniciando containers...${NC}"
docker-compose -f compose.yml up app-dev mongo-db mongo-express -d

Write-Host "${BLUE}🔍 Verificando status dos containers...${NC}"
docker-compose -f compose.yml ps

Write-Host "${BLUE}🏥 Verificando saúde da aplicação...${NC}"

$maxRetries = 30
$retryCount = 0
$healthy = $false
$initialWaitLogged = $false

while (-not $healthy -and $retryCount -lt $maxRetries) {
    try {
        $response = Invoke-WebRequest -Uri http://localhost:8080/q/health -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "`n✅ Aplicação está saudável!"
            $healthy = $true
            break
        }
    } catch {
        if (-not $initialWaitLogged -and $retryCount -ge 6) {
            Write-Host "`n⚠️ Aplicação não respondeu após 30 segundos, continuando a tentar..."
            $initialWaitLogged = $true
        } else {
            Write-Host -NoNewline "."
        }
        Start-Sleep -Seconds 5
        $retryCount++
    }
}

if (-not $healthy) {
    Write-Host "`n⚠️ Aplicação não respondeu após todas as tentativas"
}

Write-Host ""
Write-Host "${GREEN}🎉 Deploy concluído!${NC}"
Write-Host ""
Write-Host "${BLUE}🔌 Carregando extensões...${NC}"
Start-Sleep -Seconds 8
Write-Host ""
Write-Host "${BLUE}🌐 Serviços disponíveis:${NC}"
Write-Host "   - Aplicação: ${YELLOW}http://localhost:8080${NC}"
Write-Host "   - Quarkus Dev UI: ${YELLOW}http://localhost:8080/q/dev-ui/extensions${NC}"
Write-Host "   - Swagger UI: ${YELLOW}http://localhost:8080/q/swagger-ui${NC}"
Write-Host "   - Health Check: ${YELLOW}http://localhost:8080/q/health${NC}"
Write-Host "   - MongoDB Express: ${YELLOW}http://localhost:8081${NC}"
Write-Host ""
Write-Host "${BLUE}🔑 Credenciais MongoDB Express:${NC}"
Write-Host "   - Usuário: ${YELLOW}admin${NC}"
Write-Host "   - Senha: ${YELLOW}admin${NC}"
Write-Host ""
Write-Host "${BLUE}📊 Comandos úteis:${NC}"
Write-Host "   - Ver logs: ${YELLOW}docker-compose -f compose.yml logs -f shortened-app-dev${NC}"
Write-Host "   - Parar tudo: ${YELLOW}docker-compose -f compose.yml down${NC}"
Write-Host "   - Restart DB: ${YELLOW}docker-compose -f compose.yml restart mongo-db mongo-express${NC}"
Write-Host "   - Parar e remover containers: ${YELLOW}docker-compose -f compose.yml down --volumes --remove-orphans${NC}"
