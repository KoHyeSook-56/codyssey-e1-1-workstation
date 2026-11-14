# E1_1 개발 워크스테이션 구축

Linux CLI, Docker, Git을 이용해 재현 가능한 웹 실행 환경을 구성하고 검증한 과제입니다. 모든 Docker 작업은 Docker Desktop 엔진에서 실행했고, Linux 파일 실습은 WSL Ubuntu(`devuser`)에서 실행했습니다.

## 1. 실행 환경

| 항목 | 실제 확인 결과 |
| --- | --- |
| Host OS | Windows + WSL2 |
| Linux | Ubuntu WSL2, 사용자 `devuser` |
| Linux Git | `git version 2.53.0` |
| Docker Engine | Docker Desktop `29.9.2` |
| Dockerfile base image | `nginx:alpine` |

> 참고: Docker Desktop의 Ubuntu WSL 통합은 아직 활성화되지 않아 Docker CLI는 Windows PowerShell에서 실행했다. Linux CLI/권한 실습은 Ubuntu WSL에서 별도로 실행했다.

## 2. 제출 체크리스트

- [x] Linux CLI: 경로/목록/내용 확인, 생성, 복사, 이름 변경, 삭제
- [x] 파일과 디렉터리 권한: `600/700`으로 변경 후 `644/755`로 복원
- [x] Docker 엔진/버전 확인 및 `hello-world` 성공
- [x] 이미지/컨테이너/로그/리소스 사용량 확인
- [x] Ubuntu 컨테이너 `exec`와 `attach` 관찰
- [x] 직접 작성한 Dockerfile로 NGINX 이미지 빌드 및 실행
- [x] `8080:80`, `8081:80` 포트 매핑과 HTTP 응답 확인
- [x] 바인드 마운트의 즉시 반영 확인
- [x] Docker 볼륨의 컨테이너 재생성 후 데이터 유지 확인
- [x] Git 저장소 초기화 및 `main` 브랜치 설정
- [ ] GitHub 원격 저장소 연결 및 VS Code 연동 캡처

## 3. 파일 구성

```text
.
├── Dockerfile
├── site/
│   └── index.html
└── docs/
    ├── logs/
    │   ├── 01-docker-build-run.log
    │   ├── 02-bind-mount-volume-container.log
    │   └── 03-linux-cli-permissions.log
    └── screenshots/
```

## 4. Linux CLI와 권한 검증

실행 로그: [`docs/logs/03-linux-cli-permissions.log`](docs/logs/03-linux-cli-permissions.log)

```bash
cd ~/dev-workroom/practice
printf '# Linux CLI practice\n' > original.txt
cat original.txt
cp original.txt copied.txt
mv copied.txt renamed.txt
rm renamed.txt

touch permission-demo/file.txt
chmod 600 permission-demo/file.txt
chmod 700 permission-demo
chmod 644 permission-demo/file.txt
chmod 755 permission-demo
```

`r`, `w`, `x`는 각각 읽기, 쓰기, 실행(디렉터리는 진입)을 뜻한다. 세 자리 숫자는 소유자/그룹/기타 사용자의 권한을 순서대로 나타낸다. 따라서 `644`는 소유자 읽기·쓰기와 나머지 읽기, `755`는 소유자 전체 권한과 나머지 읽기·실행이다. 실습에서는 더 제한적인 `600/700`을 먼저 적용한 뒤 일반적인 파일/디렉터리 권한인 `644/755`로 복원했다.

절대 경로는 루트(`/`)부터 시작하는 전체 위치(예: `/home/devuser/dev-workroom`)이고, 상대 경로는 현재 위치를 기준으로 쓴다(예: `practice/original.txt`).

## 5. Docker 기본 검증 및 운영

실행 로그: [`docs/logs/01-docker-build-run.log`](docs/logs/01-docker-build-run.log)

```powershell
docker --version
docker info --format '{{.OperatingSystem}} | {{.ServerVersion}}'
docker run --rm hello-world
docker images codyssey-workstation-web:1.0
docker ps -a --filter name=codyssey-web
docker logs codyssey-web-8080
docker stats --no-stream codyssey-web-8080 codyssey-web-8081
```

`hello-world`는 Docker 클라이언트가 엔진에 연결하고 이미지를 내려받아 컨테이너를 실행할 수 있음을 확인한다. `docker images`는 내려받거나 빌드한 이미지, `docker ps -a`는 실행 중/종료된 컨테이너, `logs`는 표준 출력 로그, `stats --no-stream`은 일회성 CPU·메모리·I/O 측정값을 확인한다.

Ubuntu 컨테이너에는 `docker exec codyssey-volume-check-2 cat /data/proof.txt`로 실행 중인 컨테이너 안에서 명령을 수행했다. `exec`는 기존 실행 컨테이너에 별도 프로세스를 추가한다. 반면 `docker attach codyssey-attach-demo`는 컨테이너의 주 프로세스 표준 입출력에 연결하며, 이 과제에서는 `sleep 2`가 끝난 뒤 컨테이너도 `Exited (0)`이 됨을 확인했다.

## 6. Dockerfile, 포트 매핑, 접속

Dockerfile은 [`Dockerfile`](Dockerfile)에 직접 작성했다.

```dockerfile
FROM nginx:alpine
LABEL org.opencontainers.image.title="codyssey-workstation-web"
ENV APP_ENV=practice
COPY site/ /usr/share/nginx/html/
EXPOSE 80
```

- `FROM nginx:alpine`: 경량 NGINX 이미지를 기반으로 정적 웹 서버를 구성한다.
- `LABEL`: 이미지 용도 식별 메타데이터다.
- `ENV`: 컨테이너 환경값을 선언한다.
- `COPY`: 작성한 정적 웹 콘텐츠를 NGINX 기본 문서 경로에 복사한다.
- `EXPOSE 80`: 컨테이너 내부 NGINX 포트를 문서화한다.

```powershell
docker build -t codyssey-workstation-web:1.0 .
docker run -d --name codyssey-web-8080 -p 8080:80 codyssey-workstation-web:1.0
docker run -d --name codyssey-web-8081 -p 8081:80 codyssey-workstation-web:1.0
curl.exe -sS http://127.0.0.1:8080
curl.exe -sS http://127.0.0.1:8081
```

호스트 포트는 내 PC에서 접속하는 번호이고 컨테이너 포트는 컨테이너 내부 서비스 번호다. `-p 8080:80`은 호스트 `8080` 요청을 컨테이너 내부 NGINX의 `80`으로 전달한다. 같은 이미지라도 호스트 포트를 `8081`로 바꾸면 동시에 별도 컨테이너로 실행할 수 있다.

## 7. 바인드 마운트와 볼륨

실행 로그: [`docs/logs/02-bind-mount-volume-container.log`](docs/logs/02-bind-mount-volume-container.log)

```powershell
docker run -d --name codyssey-web-bind -p 8080:80 -v "${PWD}\site:/usr/share/nginx/html:ro" codyssey-workstation-web:1.0
curl.exe -sS http://127.0.0.1:8080

docker volume create codyssey-practice-data
docker run -d --name codyssey-volume-check-1 -v codyssey-practice-data:/data ubuntu sleep infinity
docker exec codyssey-volume-check-1 sh -lc 'echo volume-data-survives-container-recreation > /data/proof.txt; cat /data/proof.txt'
docker rm -f codyssey-volume-check-1
docker run -d --name codyssey-volume-check-2 -v codyssey-practice-data:/data ubuntu sleep infinity
docker exec codyssey-volume-check-2 cat /data/proof.txt
```

바인드 마운트는 호스트의 `site` 폴더를 컨테이너 문서 경로에 연결한다. `index.html`의 문구를 바꾼 뒤 이미지를 다시 빌드하지 않아도 `8080` 응답에서 **Bind mount verification** 문구가 확인됐다. `:ro`는 컨테이너에서 호스트 파일을 읽기 전용으로 다루게 한다.

볼륨은 Docker가 관리하는 영속 데이터 공간이다. 첫 컨테이너에 `proof.txt`를 작성하고 컨테이너만 제거한 뒤, 같은 볼륨을 연결한 두 번째 컨테이너에서 동일한 내용을 읽었다. 따라서 데이터는 컨테이너 생명주기와 분리되어 유지된다.

## 8. 화면 증거

화면 캡처 파일명과 캡처 방법은 [`docs/SCREENSHOT_GUIDE.md`](docs/SCREENSHOT_GUIDE.md)에 정리했다. 캡처 후 아래 상대 경로를 유지한다.

- `docs/screenshots/01-docker-engine.png`
- `docs/screenshots/02-terminal-docker-check.png`
- `docs/screenshots/03-port-8080.png`
- `docs/screenshots/04-port-8081.png`
- `docs/screenshots/05-bind-mount.png`
- `docs/screenshots/06-volume-persistence.png`
- `docs/screenshots/07-github-repository.png`

## 9. Git과 GitHub

Git은 내 PC의 변경 이력과 브랜치를 관리하는 분산 버전 관리 도구다. GitHub는 Git 저장소를 원격으로 공유·협업·제출할 수 있게 제공하는 호스팅 서비스다.

```powershell
git init -b main
git add .
git commit -m "Complete E1_1 workstation practice"
git remote add origin https://github.com/<YOUR_ACCOUNT>/<YOUR_REPOSITORY>.git
git push -u origin main
```

원격 저장소 주소와 로그인 토큰/비밀번호는 README, 로그, 캡처에 기록하지 않는다.

## 10. 실제 관찰한 문제와 해결

1. **WSL Ubuntu에서 Docker CLI가 없음**: Docker Desktop 엔진은 정상 실행 중이지만 Ubuntu WSL 통합이 비활성화되어 `docker` 명령을 찾지 못했다. 이번 검증은 Docker Desktop이 제공하는 Windows CLI로 진행했고, 이후 Docker Desktop **Settings → Resources → WSL Integration → Ubuntu**를 활성화하면 Ubuntu에서도 같은 Docker 엔진을 사용할 수 있다.
2. **Windows 셸과 Linux 셸의 인용 규칙 차이**: PowerShell에서 긴 Bash 명령을 직접 전달할 때 인용이 섞여 명령 인자가 분리됐다. Bash 스크립트를 표준 입력(`wsl -d Ubuntu -- bash -s`)으로 전달해 Linux CLI·권한 실습을 정확히 재실행했다.

## 11. 재현 순서

1. Docker Desktop을 실행해 Engine running 상태를 확인한다.
2. 이 저장소 루트에서 `docker build -t codyssey-workstation-web:1.0 .`을 실행한다.
3. 6절의 `docker run` 두 명령으로 `8080`, `8081` 컨테이너를 실행한다.
4. `http://127.0.0.1:8080`과 `http://127.0.0.1:8081`에 접속한다.
5. 7절의 명령으로 바인드 마운트와 볼륨 영속성을 재검증한다.


**E1_1 과제 예상 질문과 답변 — 실제 파일·로그 기준**

작성일: 2026-11-14

과제 설명, README, Dockerfile, site/index.html, docs/logs의 세 로그를 확인해 정리했습니다. 아래의 따옴표 안 문장은 말로 답하기 위한 예시입니다. 실행 명령은 설명용으로 적었으며, 이번 정리 작업에서 컨테이너를 다시 실행하지는 않았습니다.

먼저 연습할 질문은 1, 7, 8, 11, 13, 17, 18, 20, 25, 29번입니다. 답할 때는 ‘뜻 → 내 과제에서 한 일 → 확인한 결과’ 순서로 말하면 됩니다.

1. **이번 과제에서 무엇을 했나요?**

   “Windows에서 WSL Ubuntu로 리눅스 명령과 파일 권한을 실습했습니다. Dockerfile로 NGINX 웹 서버 이미지를 만들고, 8080과 8081 포트에서 웹페이지 응답을 확인했습니다. 바인드 마운트로 파일 변경 반영을, 볼륨으로 컨테이너 삭제 후 데이터 유지를 확인했습니다.”

   자료 위치: [README](README.md), [Dockerfile](Dockerfile), [웹페이지](site/index.html).

2. **이 과제를 하는 목적은 무엇인가요?**

   “다른 사람도 같은 절차로 개발 환경을 구성하고 실행할 수 있게 만드는 것입니다. Dockerfile과 실행 명령을 남기고, 동작 결과도 로그로 기록했습니다.”

   Docker가 모든 환경 차이를 없애는 것은 아닙니다. 이미지 버전, CPU 종류, 외부 설정 등도 영향을 줍니다.

3. **Windows인데 Ubuntu와 WSL은 왜 사용했나요?**

   “WSL은 Windows에서 리눅스 환경을 사용할 수 있게 해 주는 기능이고, Ubuntu는 그 안에서 사용한 리눅스 배포판입니다. 이 과제에서는 Ubuntu로 리눅스 명령과 권한을 실습하고, Docker 명령은 Windows PowerShell에서 실행했습니다.”

   과제 당시 README에는 Ubuntu의 Docker Desktop WSL 통합이 활성화되지 않았다고 기록되어 있습니다. 현재 설정을 다시 확인한 것은 아닙니다.

4. **터미널, 셸, PowerShell은 어떻게 다른가요?**

   “터미널은 명령을 입력하고 결과를 보는 창이고, 셸은 입력한 명령을 해석하는 프로그램입니다. PowerShell과 Bash는 셸의 종류입니다.”

5. **절대 경로와 상대 경로는 무엇인가요?**

   “절대 경로는 루트부터 적는 전체 주소이고, 상대 경로는 현재 폴더를 기준으로 적는 주소입니다. `/home/devuser/dev-workroom`은 절대 경로이고, 그 폴더 안에서 쓰는 `practice/original.txt`는 상대 경로입니다.”

   `.`은 현재 폴더, `..`은 상위 폴더입니다. `../E1_1`은 현재 위치의 상위 폴더 아래에 있는 E1_1을 가리킵니다.

6. **파일과 폴더를 다룰 때 어떤 명령을 썼나요?**

   “pwd로 현재 위치를, ls -la로 숨김 항목과 권한을 포함한 목록을 확인했습니다. cp로 복사하고, mv로 이름을 바꾸고, rm으로 실습 파일을 삭제했습니다. 파일 생성에는 touch를 사용했습니다.”

   | 명령 | 뜻 |
   | --- | --- |
   | `pwd` | 현재 위치 확인 |
   | `ls -la` | 숨김 항목을 포함한 상세 목록 |
   | `cd` | 폴더 이동 |
   | `mkdir -p` | 필요한 중간 폴더까지 생성 |
   | `touch` | 파일이 없으면 빈 파일 생성, 있으면 시간 정보 갱신 |
   | `cat` | 파일 내용 출력 |
   | `cp` | 복사 |
   | `mv` | 이동 또는 이름 변경 |
   | `rm` | 삭제 |

   증거: [Linux CLI·권한 로그](docs/logs/03-linux-cli-permissions.log).

7. **r, w, x와 644, 755는 무슨 뜻인가요?**

   “r은 읽기, w는 쓰기, x는 실행 권한입니다. 숫자는 소유자, 그룹, 그 외 사용자 순서이고, 읽기는 4, 쓰기는 2, 실행은 1을 더해서 표시합니다. 644는 소유자만 읽기·쓰기가 가능하고 나머지는 읽기만 가능합니다. 755는 소유자에게 전체 권한을, 나머지에게 읽기·실행 권한을 줍니다.”

   | 숫자 | 계산 | 권한 |
   | --- | --- | --- |
   | 7 | 4+2+1 | rwx |
   | 6 | 4+2 | rw- |
   | 5 | 4+1 | r-x |
   | 4 | 4 | r-- |

   디렉터리에서 x는 진입·경로 통과, r은 항목 이름 목록 읽기입니다. 디렉터리 안에 파일을 만들거나 삭제하려면 보통 w와 x가 함께 필요합니다.

8. **권한이 실제로 바뀌었다는 것은 어떻게 확인했나요?**

   “파일은 644에서 600으로, 폴더는 755에서 700으로 바꾼 뒤 다시 원래 값으로 복원했습니다. stat 출력으로 변경 전후 숫자가 달라지는 것을 확인했습니다.”

   로그에 남은 순서:

   ```text
   파일: 644 → 600 → 644
   폴더: 755 → 700 → 755
   ```

   600과 700은 소유자에게만 해당 권한을 주는 설정입니다.

9. **Docker는 무엇인가요?**

   “프로그램과 실행에 필요한 파일을 이미지로 준비하고, 그 이미지로 컨테이너를 만들어 실행하는 도구입니다. 실행 환경을 공유하고 반복해서 구성하는 데 도움이 됩니다.”

10. **이미지와 컨테이너는 어떻게 다른가요?**

    “이미지는 실행 환경의 바탕이 되는 묶음이고, 컨테이너는 그 이미지로 만든 개별 실행 환경입니다. 이번에는 codyssey-workstation-web:1.0 이미지 하나로 웹 컨테이너 두 개를 만들었습니다.”

    쉽게 외우면 이미지는 ‘실행 틀’, 컨테이너는 ‘그 틀로 만든 개별 환경’입니다. 중지된 컨테이너도 삭제 전까지 존재합니다.

11. **Dockerfile에서 직접 바꾼 부분은 무엇인가요?**

    “nginx:alpine을 기반으로 이미지 설명 정보와 APP_ENV 환경 변수를 추가하고, 제가 작성한 site 폴더를 NGINX 웹 경로에 복사했습니다. 핵심은 기본 페이지를 제 HTML 페이지로 바꾼 것입니다.”

    실제 파일 내용:

    ```dockerfile
    FROM nginx:alpine

    LABEL org.opencontainers.image.title="codyssey-workstation-web"
    LABEL org.opencontainers.image.description="E1_1 Dockerfile practice web server"

    ENV APP_ENV=practice

    COPY site/ /usr/share/nginx/html/

    EXPOSE 80
    ```

    | 지시어 | 이 과제에서의 역할 |
    | --- | --- |
    | `FROM` | NGINX가 준비된 베이스 이미지 선택 |
    | `LABEL` | 이미지 이름·설명 메타데이터 추가 |
    | `ENV` | APP_ENV 값을 practice로 설정 |
    | `COPY` | 빌드할 때 웹 파일을 이미지에 복사 |
    | `EXPOSE` | 컨테이너 서비스 포트 80을 문서화 |

12. **왜 nginx:alpine을 선택했나요? CMD가 없는데 왜 서버가 실행되나요?**

    “정적 HTML을 제공하는 웹 서버가 이미 준비되어 있고, Alpine 기반이라 비교적 가벼운 구성을 사용할 수 있어서 선택했습니다. 서버를 시작하는 설정은 베이스 이미지에서 물려받기 때문에 이번 Dockerfile에 CMD를 다시 쓰지 않아도 실행됩니다.”

    NGINX는 ‘엔진엑스’라고 읽습니다. 이 과제에서는 HTML을 브라우저에 전달하는 웹 서버입니다.

13. **이미지는 어떤 명령으로 빌드했나요? 마지막 점은 무엇인가요?**

    “docker build로 이미지를 만들고 -t로 이름과 태그를 붙였습니다. 마지막 점은 현재 폴더를 빌드에 사용할 파일 범위인 빌드 컨텍스트로 지정한다는 뜻입니다.”

    ```powershell
    docker build -t codyssey-workstation-web:1.0 .
    ```

    `codyssey-workstation-web`은 이미지 이름이고 `1.0`은 직접 붙인 태그입니다. 태그만으로 내용이 영구히 고정되는 것은 아닙니다.

14. **컨테이너 실행 명령의 각 옵션을 설명해 주세요.**

    ```powershell
    docker run -d --name codyssey-web-8080 -p 8080:80 codyssey-workstation-web:1.0
    ```

    “run은 새 컨테이너를 만들고 실행합니다. -d는 백그라운드 실행, --name은 컨테이너 이름 지정, -p는 호스트와 컨테이너 포트 연결입니다. 마지막에는 사용할 이미지를 적었습니다.”

15. **포트 매핑은 왜 필요하고 8080:80은 무엇인가요?**

    “내 PC에서 들어오는 요청을 컨테이너 안의 웹 서버로 전달하기 위해 사용했습니다. 앞의 8080은 내 PC의 포트이고, 뒤의 80은 컨테이너 안에서 NGINX가 요청을 받는 포트입니다.”

    요청 흐름: `브라우저 → 내 PC의 8080 → 컨테이너의 80 → NGINX → HTML 응답`.

    포트는 같은 컴퓨터에서 어떤 서비스로 요청을 보낼지 구분하는 번호라고 생각하면 됩니다.

16. **EXPOSE 80만 쓰면 브라우저에서 접속할 수 있나요?**

    “EXPOSE는 이미지가 사용하는 포트를 알려 주는 설정입니다. 이번처럼 호스트 포트로 접속하려면 docker run에서 -p로 연결해야 합니다.”

    `EXPOSE`가 NGINX의 실제 수신 포트를 바꾸는 것도 아닙니다. 이 이미지의 NGINX 설정이 80을 사용합니다.

17. **왜 8080과 8081을 둘 다 사용했나요? 내부 80번 포트가 겹치지 않나요?**

    “같은 이미지에서 여러 컨테이너를 실행할 수 있음을 확인하기 위해서입니다. 기본 네트워크에서는 컨테이너마다 네트워크 공간이 분리되어 내부 80번 포트를 각각 쓸 수 있습니다. 호스트 쪽은 충돌하지 않도록 8080과 8081로 나눴습니다.”

    증거: [빌드·포트 접속 로그](docs/logs/01-docker-build-run.log), [8080 화면](docs/screenshots/03-port-8080.png), [8081 화면](docs/screenshots/04-port-8081.png).

18. **바인드 마운트는 무엇이고, 어떻게 검증했나요?**

    “내 PC의 site 폴더를 컨테이너의 웹 폴더에 연결하는 것입니다. 호스트 HTML 문구를 수정한 뒤 이미지를 다시 빌드하지 않고 8080 응답에서 변경된 문구를 확인했습니다.”

    실제 연결 옵션:

    ```powershell
    -v "${PWD}\site:/usr/share/nginx/html:ro"
    ```

    `${PWD}\site`는 PowerShell의 현재 폴더 아래 site이고, `/usr/share/nginx/html`은 컨테이너 안의 NGINX 웹 경로입니다. `:ro`는 컨테이너 쪽에서 읽기 전용으로 연결한다는 뜻입니다. 호스트에서 파일을 수정하는 것은 가능합니다.

    변경 전 응답은 01번 로그의 `Initial image content`, 변경 후 응답은 02번 로그의 `Bind mount verification`에서 비교할 수 있습니다.

19. **COPY와 바인드 마운트는 어떻게 다른가요?**

    “COPY는 이미지를 빌드할 때 파일을 넣는 것이고, 바인드 마운트는 컨테이너를 실행할 때 호스트 폴더를 연결하는 것입니다. COPY만 썼다면 호스트 파일을 수정해도 기존 이미지 내용은 바뀌지 않습니다. 바인드 마운트한 웹 파일은 호스트의 수정 내용이 연결된 경로에 보입니다.”

    같은 경로에 마운트하면 이미지에 들어 있던 그 경로의 파일은 마운트 뒤에 가려집니다. 원래 이미지 파일이 수정되거나 삭제되는 것은 아닙니다.

20. **Docker 볼륨은 무엇이고, 데이터 유지를 어떻게 검증했나요?**

    “볼륨은 Docker가 관리하는 별도 저장 공간입니다. codyssey-practice-data 볼륨에 proof.txt를 저장한 뒤 첫 컨테이너를 삭제했습니다. 같은 볼륨을 새 컨테이너에 연결하고 파일을 읽었더니 내용이 그대로 남아 있었습니다.”

    실제 연결: `-v codyssey-practice-data:/data`.

    실제 검증 흐름:

    ```text
    볼륨 생성 → 첫 컨테이너의 /data/proof.txt에 기록
    → 첫 컨테이너 삭제 → 같은 볼륨을 두 번째 컨테이너에 연결
    → /data/proof.txt를 읽어 같은 내용 확인
    ```

    삭제 전후 출력: `volume-data-survives-container-recreation`.

    증거: [마운트·볼륨 로그](docs/logs/02-bind-mount-volume-container.log), [볼륨 확인 화면](docs/screenshots/06-volume-persistence.png).

21. **바인드 마운트와 볼륨은 무엇이 다른가요?**

    “바인드 마운트는 제가 지정한 호스트 폴더를 연결하고, 볼륨은 Docker가 관리하는 저장 공간을 연결합니다. 이번 과제에서는 바인드 마운트로 웹 파일 수정을 반영하고, 볼륨으로 컨테이너를 교체해도 데이터를 유지했습니다.”

    둘 다 컨테이너와 별도로 데이터를 유지할 수 있습니다. 볼륨의 차이를 ‘볼륨만 데이터가 남는다’고 설명하지 않도록 합니다.

22. **컨테이너를 중지했다 켜는 것만으로 영속성이 검증되나요?**

    “중지와 재시작은 같은 컨테이너를 사용하는 것이어서 이번 과제의 삭제 후 재생성 조건을 충분히 증명하지 못합니다. 그래서 첫 컨테이너를 삭제하고 다른 컨테이너에서 같은 볼륨의 파일을 읽었습니다.”

    볼륨 자체를 삭제하면 데이터를 잃을 수 있습니다. 볼륨은 자동 백업 기능이 아닙니다.

23. **docker run, start, stop, rm은 어떻게 다른가요?**

    “run은 새 컨테이너 생성과 실행, start는 기존 컨테이너 시작, stop은 중지, rm은 컨테이너 삭제입니다. stop만으로 컨테이너가 삭제되지는 않습니다.”

    이 과제의 볼륨 테스트에서는 `docker rm -f codyssey-volume-check-1`로 첫 실습 컨테이너를 중지·삭제했습니다.

24. **컨테이너 상태와 문제는 어떤 명령으로 확인하나요?**

    “docker ps로 실행 상태를 보고, docker ps -a로 중지된 컨테이너까지 확인합니다. docker logs로 출력 로그를, docker stats --no-stream으로 CPU와 메모리 사용량을 확인합니다.”

    웹 접속 실패 시에는 엔진 연결(`docker info`), 컨테이너 상태, 로그, 포트 매핑을 차례로 확인한다고 답하면 됩니다. 버전 출력만으로 엔진 정상 동작까지 증명되지는 않습니다.

25. **exec와 attach는 어떻게 다른가요? exit하면 컨테이너가 종료되나요?**

    “exec는 실행 중인 컨테이너에서 새 명령을 실행하고, attach는 기존 주 프로세스의 입출력에 연결합니다. exec로 연 셸에서 exit하면 보통 그 셸만 끝나지만, 컨테이너의 주 프로세스가 끝나면 컨테이너도 중지됩니다.”

    실제 실습에서는 `docker exec`로 파일을 읽었습니다. attach 실습의 주 프로세스는 `sleep 2`였고, 2초 뒤 그 프로세스가 끝나 `Exited (0)`이 되었습니다. attach 자체가 컨테이너를 종료시켰다고 설명하지 않습니다.

26. **Git과 GitHub는 어떻게 다른가요?**

    “Git은 변경 이력을 관리하는 도구이고, GitHub는 Git 저장소를 온라인으로 공유하고 협업하는 서비스입니다. Git으로 내 PC에 커밋을 만들고 push로 원격 저장소에 전달합니다.”

27. **add, commit, push와 main은 무엇인가요?**

    “add는 다음 커밋에 넣을 변경을 선택하고, commit은 선택한 변경을 로컬 이력으로 기록하고, push는 그 커밋을 원격 저장소에 전달합니다. main은 이 과제에서 사용한 브랜치 이름입니다.”

    `git config user.name`과 `user.email`은 커밋 작성자 정보이며 GitHub 로그인 설정이 아닙니다.

28. **README와 로그는 왜 작성했나요?**

    “다른 사람이 실행 방법을 따라 해 보고 결과를 확인할 수 있도록 하기 위해서입니다. README에 목표와 환경, 명령, 문제 해결 과정을 쓰고 docs/logs와 스크린샷으로 근거를 연결했습니다.”

    실행했다고 말하는 것과 실행 결과를 증명하는 것은 다릅니다. 명령과 출력이 함께 있는 위치를 보여 주면 좋습니다.

29. **실제로 어려웠던 문제와 해결 방법을 설명해 주세요.**

    첫 사례:

    “Ubuntu에서 docker 명령을 사용할 수 없었습니다. 과제 기록상 Docker Desktop의 Ubuntu WSL 통합이 꺼져 있었고, Windows PowerShell에서는 엔진에 연결할 수 있었습니다. 그래서 이번 실습은 PowerShell의 Docker CLI로 진행했습니다.”

    두 번째 사례:

    “PowerShell에서 긴 Bash 명령을 전달할 때 따옴표 처리 때문에 인자가 잘못 전달되는 문제가 있었습니다. Bash 스크립트를 표준 입력으로 wsl -d Ubuntu -- bash -s에 전달하는 방식으로 바꾸어 파일·권한 실습 결과를 기록했습니다.”

    근거: [README의 문제 해결 기록](README.md). Linux 로그의 마지막 `git --version` 부분에는 오류가 남아 있으므로 모든 명령이 오류 없이 성공했다고 말하지 않습니다.

30. **지금 웹 서버를 다시 실행하려면 무엇을 해야 하나요?**

    “Docker Desktop을 실행하고 저장소 루트에서 이미지를 빌드합니다. 사용할 컨테이너 이름과 호스트 포트가 비어 있는지 확인한 뒤 docker run으로 실행하고, 브라우저나 curl로 응답을 확인합니다.”

    설명용 재현 명령:

    ```powershell
    docker build -t codyssey-workstation-web:1.0 .
    docker run -d --name codyssey-web-8080 -p 8080:80 codyssey-workstation-web:1.0
    curl.exe -sS http://127.0.0.1:8080
    ```

    이미 그 이름의 컨테이너가 있으면 새 run이 실패할 수 있습니다. 또한 바인드 마운트용 컨테이너도 호스트 8080을 사용하므로, 기존 8080 컨테이너와 동시에 실행할 수 없습니다. 실제 02번 로그에서는 기존 컨테이너를 중지·삭제한 다음 바인드 마운트 컨테이너를 실행했습니다.

31. **이 구현에서 더 개선하고 싶은 점은 무엇인가요?**

    “베이스 이미지의 버전이나 digest를 고정해 재현성을 높이고, README의 체크리스트와 실제 증거 파일 목록을 맞추고 싶습니다. 선택 과제로 Compose 파일을 작성하면 긴 실행 옵션도 파일로 관리할 수 있습니다.”

    현재 폴더에서 Compose 파일은 확인되지 않았으므로 Compose 실습까지 구현했다고 답하지 않습니다. `ENV APP_ENV=practice`도 현재 HTML이나 NGINX 설정에서 읽어 동작을 바꾸지는 않습니다. 환경 변수를 선언한 것과 실제로 기능에 사용한 것은 구분합니다.

32. **과제를 하면서 무엇을 배웠나요?**

    “이미지를 만드는 과정과 컨테이너를 실행하는 과정이 다르고, 포트로 외부 접속을 연결하며, 저장 공간을 따로 두면 컨테이너를 바꿔도 데이터를 유지할 수 있다는 것을 배웠습니다. 결과를 로그로 남겨야 다른 사람도 확인할 수 있다는 점도 배웠습니다.”

**30초 소개 연습문**

“이번 과제는 개발 환경을 직접 구성하고 결과를 확인하는 실습이었습니다. WSL Ubuntu에서 파일과 권한을 다루고, NGINX 기반 Docker 이미지로 웹페이지를 실행했습니다. 호스트 8080과 8081을 컨테이너 내부 80에 연결해 응답을 확인했습니다. 바인드 마운트로 웹 파일 변경을 반영하고, 볼륨으로 컨테이너 삭제 후에도 데이터가 남는 것을 검증했습니다.”

**질문 전에 확인할 실제 기록의 차이**

- 기존 `답변.md`는 완료를 가정한 연습문이며 `workroom-web:1.0` 같은 예시가 있습니다. 이번 구현의 실제 이미지 이름은 `codyssey-workstation-web:1.0`입니다.
- README에는 GitHub·VS Code 연동 항목이 미체크로 남아 있습니다. GitHub 저장소 화면 파일은 있지만 VS Code 로그인·연동을 직접 입증하는 별도 캡처는 현재 폴더에서 확인되지 않았습니다.
- README의 화면 목록은 7개이지만 현재 저장된 스크린샷은 03, 04, 06, 07번 4개입니다. 마운트 변경은 01·02번 로그에서 비교할 수 있습니다.
- README에는 hello-world 성공으로 기록되어 있지만, 현재 세 로그에는 그 성공 출력이 없습니다. 현장에서 근거를 요구하면 재실행 결과를 보여 주거나 해당 출력이 별도로 필요하다고 설명해야 합니다.
- 이번 자료 정리에서는 현재 Docker 실행 상태와 GitHub 원격 상태를 다시 검사하지 않았습니다. 과제 당시 기록과 지금의 실행 상태를 구분해 답합니다.
