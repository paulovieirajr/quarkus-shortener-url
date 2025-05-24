# Encurtador de URL com Quarkus e MongoDB

![Java](https://img.shields.io/badge/Java-21-green?style=plastic&logo=java)
![Quarkus](https://img.shields.io/badge/Quarkus-3.22.3-black?style=plastic&logo=quarkus&logoColor=white&logoSize=auto&labelColor=blue)
![MongoDB](https://img.shields.io/badge/MongoDB-green?style=plastic&logo=mongodb&labelColor=gray)
![JUnit](https://img.shields.io/badge/JUnit-5-green?style=plastic&)
![Maven](https://img.shields.io/badge/Apache_Maven-red?logo=apachemaven&logoColor=%23FFF)
![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=fff)

## Descrição

Este projeto é um encurtador de URL desenvolvido com Quarkus e MongoDB. Ele permite que os usuários encurtem URLs longas
e as acessem através de um link curto gerado.

## Funcionalidades

- Encurtamento de URLs longas
- Redirecionamento de URLs geradas para o link original

## Como usar

1. Clone o repositório:
   ```bash
   https://github.com/paulovieirajr/quarkus-shortener-url.git
    ```

2. Navegue até o diretório do projeto:
   ```bash
   cd shortener-url
   ```

3. Execute o script para iniciar a aplicação em modo de desenvolvimento:

    - Caso esteja usando Linux ou MacOS:
   ```bash
    ./build.sh
    ```
    - Caso esteja usando Windows, no PowerShell execute:
    ```bash
    .\build.ps1
    ```
4. Caso queira experimentar o modo nativo, é necessário o Java 21 instalado por causa do mvnw. A GraalVM vai ser baixada
   automaticamente via Dockerfile.

    - No Linux ou MacOS, execute:
   ```bash
    ./build-native.sh
    ```
    - No Windows, no PowerShell execute:
    ```bash
    .\build-native.ps1
    ```

5. Após a execução do script, instruções para acessar a aplicação serão exibidas no terminal. A Dev UI e o Swagger UI
   fica disponível apenas no modo de desenvolvimento.
   
   ![image](https://github.com/user-attachments/assets/dff2ca75-9e12-41f9-8ddf-57ab66fdd5ad)

7. Use o endpoint `/create` para encurtar URLs.

8. Copie o link encurtado gerado e cole no navegador para redirecionar para a URL original.

9. É possível acessar a interface do MongoDB através do Mongo Express:
   ```bash
   http://localhost:8081/
   ```
    - Usuário: `admin`
    - Senha: `admin`
    - Database: `shortener`
    - Collection: `ShortenedUrl`
      <br>

<details>
    <summary>Instruções padrão geradas automaticamente ao criar o Projeto Quarkus - Clique aqui</summary>

This project uses Quarkus, the Supersonic Subatomic Java Framework.

If you want to learn more about Quarkus, please visit its website: <https://quarkus.io/>.

## Running the application in dev mode

You can run your application in dev mode that enables live coding using:

```shell script
./mvnw quarkus:dev
```

> **_NOTE:_**  Quarkus now ships with a Dev UI, which is available in dev mode only at <http://localhost:8080/q/dev/>.

## Packaging and running the application

The application can be packaged using:

```shell script
./mvnw package
```

It produces the `quarkus-run.jar` file in the `target/quarkus-app/` directory.
Be aware that it’s not an _über-jar_ as the dependencies are copied into the `target/quarkus-app/lib/` directory.

The application is now runnable using `java -jar target/quarkus-app/quarkus-run.jar`.

If you want to build an _über-jar_, execute the following command:

```shell script
./mvnw package -Dquarkus.package.jar.type=uber-jar
```

The application, packaged as an _über-jar_, is now runnable using `java -jar target/*-runner.jar`.

## Creating a native executable

You can create a native executable using:

```shell script
./mvnw package -Dnative
```

Or, if you don't have GraalVM installed, you can run the native executable build in a container using:

```shell script
./mvnw package -Dnative -Dquarkus.native.container-build=true
```

You can then execute your native executable with: `./target/shortener-url-1.0.0-SNAPSHOT-runner`

If you want to learn more about building native executables, please consult <https://quarkus.io/guides/maven-tooling>.

## Related Guides

- REST ([guide](https://quarkus.io/guides/rest)): A Jakarta REST implementation utilizing build time processing and
  Vert.x. This extension is not compatible with the quarkus-resteasy extension, or any of the extensions that depend on
  it.
- REST Jackson ([guide](https://quarkus.io/guides/rest#json-serialisation)): Jackson serialization support for Quarkus
  REST. This extension is not compatible with the quarkus-resteasy extension, or any of the extensions that depend on it

## Provided Code

### REST

Easily start your REST Web Services

[Related guide section...](https://quarkus.io/guides/getting-started-reactive#reactive-jax-rs-resources)
</details>
