# DevOps 사전과제
![Build Maven](https://github.com/spring-petclinic/spring-petclinic-data-jdbc/workflows/Build%20Maven/badge.svg)

## 과제내용
웹 어플리케이션 [spring-petclinic-data-jdbc](https://github.com/spring-petclinic/spring-petclinic-data-jdbc)을 kubernetes 환경에서 실행하고자 합니다.
- 다음의 요구 사항에 부합하도록 빌드 스크립트, 어플리케이션 코드 등을 작성하십시오.
- kubernetes에 배포하기 위한 manifest 파일을 작성하십시오.

## 요구사항
- gradle을 사용하여 어플리케이션과 도커이미지를 빌드한다.
- 어플리케이션의 log는 host의 /logs 디렉토리에 적재되도록 한다.
- 정상 동작 여부를 반환하는 api를 구현하며, 10초에 한번 체크하도록 한다. 3번 연속 체크에 실패하면 어플리케이션은 restart 된다.
- 종료 시 30초 이내에 프로세스가 종료되지 않으면 SIGKILL로 강제 종료 시킨다.
- 배포 시와 scale in/out 시 유실되는 트래픽이 없어야 한다.
- 어플리케이션 프로세스는 root 계정이 아닌 uid:1000으로 실행한다.
- DB도 kubernetes에서 실행하며 재 실행 시에도 변경된 데이터는 유실되지 않도록 설정한다.
- 어플리케이션과 DB는 cluster domain을 이용하여 통신한다.
- nginx-ingress-controller를 통해 어플리케이션에 접속이 가능하다.
- namespace는 default를 사용한다.
- README.md 파일에 실행 방법을 기술한다.

## 제출방법
파일을 메일에 첨부하거나 git repository 주소를 제출하십시오.

# DevOps 사전과제 수행
## 테스트 환경
  ~~~
  - Ubuntu 20.04.1 LTS
  - Gradle 6.6.1
  - Docker 19.03.12
  - Git 2.25.1
  - Helm 3.2.0
  - kubectl 1.18.8
  - java
    openjdk version "1.8.0_265"
    OpenJDK Runtime Environment (build 1.8.0_265-8u265-b01-0ubuntu2~20.04-b01)
    OpenJDK 64-Bit Server VM (build 25.265-b01, mixed mode)
  ~~~

## 실행 방법
  - 변수 / domain 설정
    ~~~bash
    $ export DOCKER_ID=dockerId
    $ export DOCKER_PASSWORD=dockerPassword
    $ export TEST_DOMAIN=kakaopay.petclinic.com
    $ export TEST_DOMAIN_IP=localhost # hosts 설정 변경이 필요한 경우에 사용
    $ echo "${TEST_DOMAIN_IP} ${TEST_DOMAIN}" >> /etc/hosts # hosts 설정 변경이 필요한 경우에 사용
    ~~~
  - 소스 받기
    ~~~bash
    $ git clone https://github.com/kimytsc/spring-petclinic-data-jdbc -b kakaopay
    $ cd spring-petclinic-data-jdbc
    ~~~
  - build & docker push
    ~~~bash
    $ ./gradlew dockerPush -Pid=${DOCKER_ID} -Ppw=${DOCKER_PASSWORD}
    ~~~
  - Helm deploy
    ~~~bash
    $ helm upgrade petclinic.database ./helm/database/mysql --wait --debug --install
    $ helm upgrade petclinic.application ./helm/application/java --wait --debug --install \
      --set image.repository=${DOCKER_ID}/spring-petclinic-data-jdbc \
      --set ingress.hosts[0].host=${TEST_DOMAIN} \
      --set ingress.hosts[0].paths[0]="/"
    ~~~

## 요구사항 구현
  - gradle을 사용하여 어플리케이션과 도커이미지를 빌드한다.
    - `/pom.xml`에 `https://repo.maven.apache.org/maven2` repositories 추가([pom.xml#L288](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/pom.xml#L288),
        [pom.xml#L316](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/pom.xml#L316))
    - `gradle init -type pom`
    - 생성된 `build.gradle`에 `docker`([build.gradle#L2](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/build.gradle#L2),
      [build.gradle#L79](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/build.gradle#L79),
      [build.gradle#L92](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/build.gradle#L92)),
      `dockerPush`([build.gradle#L86](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/build.gradle#L86)),
      `ext`([build.gradle#L11](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/build.gradle#L11)),
      `wro4j`([build.gradle#L6](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/build.gradle#L6),
      [build.gradle#L9](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/build.gradle#L9),
      [build.gradle#L20](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/build.gradle#L20),
      [build.gradle#L67](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/build.gradle#L67))
      추가

  - 어플리케이션의 log는 host의 /logs 디렉토리에 적재되도록 한다.
    - `org.springframework.boot:spring-boot-starter-web`에 포함되어 있는 `org.springframework.boot:spring-boot-starter-logging`을 활용
    - `/src/main/resources/logback.xml`([logback.xml#L1](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/src/main/resources/logback.xml)) 추가
    - `/src/main/resources/application.properties`([application.properties#L1](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/src/main/resources/application.properties))에서 `logging.level.org.springframework.web=DEBUG`([application.properties#L31](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/src/main/resources/application.properties#L31)) 주석 해제
    - host의 `/logs`([deployment.yaml#L55](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/deployment.yaml#L55))를 container의 log 경로([deployment.yaml#L51](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/deployment.yaml#L51))에 bind

  - 정상 동작 여부를 반환하는 api를 구현하며, 10초에 한번 체크하도록 한다. 3번 연속 체크에 실패하면 어플리케이션은 restart 된다.
    - `spring-boot-actuator`의 `component`를 설정, `/health/petclinic` API([PetClinic.java#L1](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/src/main/java/org/springframework/samples/petclinic/health/PetClinic.java)) 추가
    - 10초에 한번씩 체크하도록 `.spec.template.spec.containers.livenessProbe.periodSeconds`([deployment.yaml#L45](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/deployment.yaml#L45)) 설정
    - 3번 연속 체크 실패 확인을 위해 `.spec.template.spec.containers.livenessProbe.failureThreshold`([deployment.yaml#L44](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/deployment.yaml#L44)) 설정
    - 테스트를 위한 health UP([HealthController.java#L19](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/src/main/java/org/springframework/samples/petclinic/health/HealthController.java#L19)), DOWN([HealthController.java#L24](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/src/main/java/org/springframework/samples/petclinic/health/HealthController.java#L24)) 구현

  - 종료 시 30초 이내에 프로세스가 종료되지 않으면 SIGKILL로 강제 종료 시킨다.
    - `.spec.template.spec.terminationGracePeriodSeconds: 30`([values.yaml#L14](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/values.yaml#L14),
      [deployment.yaml#L54](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/deployment.yaml#L54)) 설정
    - 테스트를 위해 `.spec.template.spec.containers[].lifecycle.preStop.exec.command`([deployment.yaml#L47](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/deployment.yaml#L47)) 설정

  - 배포 시와 scale in/out 시 유실되는 트래픽이 없어야 한다.
    - 순차적으로 배포되도록 `.spec.strategy.type: rollingUpdate`([deployment.yaml#L13](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/deployment.yaml#L13)) 설정
    - 정상적으로 부팅된 후에 진행되도록 `.spec.template.spec.containers.startupProbe`([deployment.yaml#L33](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/deployment.yaml#L33)) 설정

  - 어플리케이션 프로세스는 root 계정이 아닌 uid:1000으로 실행한다.
    - wavefront token 저장을 위해 docker build시 uid:1000 계정 정보 생성([Dockerfile#L8](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/docker/Dockerfile#L8)) 설정 추가
    - 빌드된 어플리케이션을 uid:1000으로 이미지에 복사([Dockerfile#L19](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/docker/Dockerfile#L19))
    - uid:1000으로 실행하도록 `spec.template.spec.containers[].securityContext.runAsUser`([values.yaml#L16](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/values.yaml#L16) -> [deployment.yaml#L26](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/deployment.yaml#L26)) 설정

  - DB도 kubernetes에서 실행하며 재 실행 시에도 변경된 데이터는 유실되지 않도록 설정한다.
    - [mysql](https://github.com/kimytsc/spring-petclinic-data-jdbc/tree/kakaopay/helm/database/mysql) helm 추가
    - `PersistentVolumeClaim`([persistentVolumeClaim.yaml#L1](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/database/mysql/templates/persistentVolumeClaim.yaml),
      [deployment.yaml#L37](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/database/mysql/templates/deployment.yaml#L37)) 설정
    - `PersistentVolumeClaim`를 `/var/lib/mysql`([deployment.yaml#L32](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/database/mysql/templates/deployment.yaml#L32))에 마운트

  - 어플리케이션과 DB는 cluster domain을 이용하여 통신한다.
    - `CoreDNS`를 통해 `{.metadata.name}.{.metadata.namespace}.svc.cluster.local` 형식으로 생성된 `mysql.default.svc.cluster.local` 사용
    - DB 접속정보([application.properties#L2](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/src/main/resources/application.properties#L2)) 수정

  - nginx-ingress-controller를 통해 어플리케이션에 접속이 가능하다.
    - 도메인([values.yaml#L28](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/values.yaml#L28) -> [ingress.yaml#L21](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/ingress.yaml#L21)) 설정
    - `nginx-ingress-controller`를 사용하기 위해 `.metadata.annotations[kubernetes.io/ingress.class]`([values.yaml#L25](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/values.yaml#L25) -> [ingress.yaml#L16](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/ingress.yaml#L16)) 설정

  - namespace는 default를 사용한다.
    - helm 배포시 `--namespace` 설정 기본값이 `default`
    - 직접 지정을 위해 `namespace`([values.yaml#L8](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/values.yaml#L8) ->
      [deployment.yaml#L5](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/deployment.yaml#L5),
      [ingress.yaml#L12](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/ingress.yaml#L12),
      [service.yaml#L5](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/helm/application/java/templates/service.yaml#L5)) 추가

  - README.md 파일에 실행 방법을 기술한다.
    - [README.md](https://github.com/kimytsc/spring-petclinic-data-jdbc/blob/kakaopay/readme.md#%EC%8B%A4%ED%96%89-%EB%B0%A9%EB%B2%95)
