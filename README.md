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
- `docs/screenshots/07-github-vscode.png`

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
