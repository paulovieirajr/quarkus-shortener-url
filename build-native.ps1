param(
    [switch]$restart,
    [switch]$skipNative,
    [switch]$skipDocker,
    [switch]$help
)

$ErrorActionPreference = "Stop"

$GREEN = "`e[0;32m"
$YELLOW = "`e[1;33m"
$BLUE = "`e[0;34m"
$RED = "`e[0;31m"
$NC = "`e[0m"

function Check-NativeBinary {
    $files = Get-ChildItem -Path "target" -Filter "*-runner" -ErrorAction SilentlyContinue
    if ($files) {
        Write-Host "$GREEN✅ Binário nativo encontrado: $($files.Name)$NC"
        return $true
    } else {
        Write-Host "$YELLOW⚠️  Binário nativo não encontrado$NC"
        return $false
    }
}

function Check-DockerImage {
    if (docker image inspect paulovieirajr/shortener-url-native:latest >$null 2>&1) {
        Write-Host "$GREEN✅ Imagem Docker encontrada: paulovieirajr/shortener-url-native:latest$NC"
        return $true
    } else {
        Write-Host "$YELLOW⚠️  Imagem Docker não encontrada$NC"
        return $false
    }
}

$RESTART = $false
$SKIP_NATIVE = $false
$SKIP_DOCKER = $false

if ($help) {
    Write-Host "$BLUE📖 Uso do script:$NC"
    Write-Host "  .\build-native.ps1                   # Compila app nativo e imagem Docker"
    Write-Host "  .\build-native.ps1 -restart          # Força rebuild completo"
    Write-Host "  .\build-native.ps1 -skipNative       # Pula compilação nativa"
    Write-Host "  .\build-native.ps1 -skipDocker       # Pula build da imagem Docker"
    Write-Host "  .\build-native.ps1 -help             # Mostra esta ajuda"
    exit 0
}

$RESTART = $restart
$SKIP_NATIVE = $skipNative
$SKIP_DOCKER = $skipDocker

if (-not $RESTART -and -not $SKIP_NATIVE -and -not $SKIP_DOCKER) {
    Write-Host "$BLUE🔍 Verificando estados atuais...$NC"
    $containers = docker ps -q --filter "name=app" --filter "name=mongo-db" --filter "name=mongo-express"
    if ($containers) {
        Write-Host ""
        Write-Host "$GREEN✅ Containers já estão rodando!$NC"
        Write-Host ""
        Write-Host "$BLUE🔌 Listando containers...$NC"
        docker ps --filter "name=app" --filter "name=mongo-db" --filter "name=mongo-express"
        Write-Host ""
        Write-Host "$YELLOW⚠️  Para reiniciar os containers, use: .\build-native.ps1 -restart$NC"
        exit 0
    }
}

if ($SKIP_NATIVE) {
    Write-Host "$YELLOW⏭️  Pulando compilação nativa (-skipNative)$NC"
}
elseif ($RESTART -or -not (Check-NativeBinary)) {
    Write-Host "$BLUE🔧 Compilando binário nativo...$NC"
    .\mvnw clean package -Dnative "-DskipTests" "-Dquarkus.native.container-build=true" "-Dquarkus.native.builder-image=quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21"
    Write-Host "$GREEN✅ Binário nativo compilado com sucesso!$NC"
}
else {
    Write-Host "$GREEN⏭️  Binário nativo já existe, pulando compilação$NC"
}

if ($SKIP_DOCKER) {
    Write-Host "$YELLOW⏭️  Pulando build da imagem Docker (-skipDocker)$NC"
}
elseif ($RESTART -or -not (Check-DockerImage)) {
    Write-Host "$BLUE🐳 Buildando imagem Docker...$NC"
    docker build -f src/main/docker/Dockerfile.native-micro -t paulovieirajr/shortener-url-native:latest .
    Write-Host "$GREEN✅ Imagem Docker criada com sucesso!$NC"
}
else {
    Write-Host "$GREEN⏭️  Imagem Docker já existe, pulando build$NC"
}

Write-Host "$BLUE🧹 Limpando containers anteriores...$NC"
docker-compose -f compose.yml down --remove-orphans | Out-Null

Write-Host "$BLUE🚀 Iniciando containers...$NC"
docker-compose -f compose.yml up app mongo-db mongo-express -d

Write-Host "$BLUE🔍 Verificando status dos containers...$NC"
docker-compose -f compose.yml ps

Write-Host "$BLUE🏥 Verificando saúde da aplicação...$NC"

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
Write-Host "$GREEN🎉 Deploy concluído!$NC"
Write-Host ""
Write-Host "$BLUE🔌 Carregando extensões...$NC"
Start-Sleep -Seconds 8
Write-Host ""
Write-Host "$BLUE🌐 Serviços disponíveis:$NC"
Write-Host "   - Aplicação: ${YELLOW}http://localhost:8080${NC}"
Write-Host "   - Health Check: ${YELLOW}http://localhost:8080/q/health${NC}"
Write-Host "   - MongoDB Express: ${YELLOW}http://localhost:8081${NC}"
Write-Host ""
Write-Host "$RED⚠️ Quarkus Dev UI e Swagger UI não estão disponíveis no modo nativo!$NC"
Write-Host ""
Write-Host "$BLUE🔑 Credenciais MongoDB Express:$NC"
Write-Host "   - Usuário: ${YELLOW}admin${NC}"
Write-Host "   - Senha: ${YELLOW}admin${NC}"
Write-Host ""
Write-Host "$BLUE📊 Comandos úteis:$NC"
Write-Host "   - Ver logs: ${YELLOW}docker-compose -f compose.yml logs -f app${NC}"
Write-Host "   - Parar tudo: ${YELLOW}docker-compose -f compose.yml down${NC}"
Write-Host "   - Restart DB: ${YELLOW}docker-compose -f compose.yml restart mongo-db mongo-express${NC}"
Write-Host "   - Parar e remover containers: ${YELLOW}docker-compose -f compose.yml down --volumes --remove-orphans${NC}"
