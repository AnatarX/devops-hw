# ДЗ 1: Фундамент DevOps-инфраструктуры

Сервер `111.88.162.121`, Ubuntu 24.04.

- `ansible/` - настройка сервера: пользователь deployer, docker, ufw
- `terraform/` - nginx в отдельной docker сети с томом, порт 8080 (провайдер kreuzwerker/docker)
- `app/` - docker compose: nginx (proxy) + app (hello world), порт 80
- `scripts/monitor.sh` - проверка сервиса и ошибок в syslog

## Запуск

Сначала ansible, потом terraform.

```bash
# 1. ansible
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook setup_host.yml

# 2. terraform
cd ../terraform
terraform init
terraform apply
curl -i http://111.88.162.121:8080

# 3. compose
cd ../ansible
ansible-playbook deploy_app.yml
curl -i http://111.88.162.121

# 4. monitor.sh
cd ..
./scripts/monitor.sh docker
```

## Скриншоты

terraform state list:

![](docs/screenshots/01-terraform-state.png)

nginx от terraform на 8080, сеть и том:

![](docs/screenshots/01b-terraform-docker.png)

ansible, второй запуск (changed=0):

![](docs/screenshots/02-ansible-idempotency.png)

monitor.sh на сервере:

![](docs/screenshots/03-monitor-server.png)

monitor.sh локально (на arch нет /var/log/syslog, считает через journalctl):

![](docs/screenshots/03-monitor-local.png)

docker-compose ps и curl:

![](docs/screenshots/04-compose-curl.png)

пользователи и firewall:

![](docs/screenshots/05-iam-firewall.png)

автозапуск:

![](docs/screenshots/06-autostart.png)

Логи запусков в `docs/outputs`.

## Что и почему

**Terraform.** Провайдер docker ходит на сервер по ssh под deployer, docker api наружу не открыт. В main.tf создаются сеть `devops-hw1-net`, том `devops-hw1-html` и контейнер nginx на порту 8080 (80 занят compose). Compose работает в своих сетях `app_frontend` и `app_backend`. Также terraform создаёт пользователя `vm-operator`.

**Пользователи.** `deployer` - sudo без пароля, группа docker. `vm-operator` - через sudo может только перезапускать и смотреть docker. Root по ssh запрещён, для student и deployer вход только по ключу.

**Firewall.** Всё закрыто, ssh только с моего IP, 80 и 8080 открыты. Docker публикует порты в обход ufw, это надо учитывать.

**Compose.** Наружу открыт только nginx, app в internal сети без интернета.

**monitor.sh.** Проверяет `systemctl is-active`, если сервис не работает - выводит 10 строк из journalctl. Ошибки за час считает через grep и awk по `/var/log/syslog`. Код выхода 0 - работает, 1 - не работает, 2 - ошибка.

## Проблемы

- Сначала делал VM в VirtualBox, провайдер зависал на apply (ждал IP на всех сетевых картах). Потом сказали использовать docker провайдер.
- terraform plan каждый раз хотел пересоздать сеть - помогло явно указать gateway.
- ufw limit на ssh резал подключения, когда запускал много команд подряд.
- grep без совпадений возвращает 1, из-за `set -o pipefail` скрипт падал, добавил `|| true`.
- ansible ругался что apt_repository устарел, заменил на deb822_repository.

## Вопросы

1. Bash/Ansible - описываешь шаги, Terraform - описываешь результат, он сам считает что поменять.
2. В state хранится что уже создано. Если удалить, terraform попробует создать всё заново и упадёт, потому что сеть с таким именем уже есть.
3. Идемпотентность - повторный запуск ничего не меняет. Проверял вторым запуском playbook, там changed=0.
4. Если сервис не найден - выводит ошибку и выходит с кодом 2. Если лог пустой - пишет предупреждение. Если нет syslog - считает через journalctl.
5. Открыты только нужные порты, ssh только с моего IP и только по ключу, root запрещён.
