# Размещение, упаковка и жизненный цикл workloads: host, VM, Compose и Dev Containers

**Исследовательский вопрос:** как профессионально выбирать место исполнения, границу жизненного цикла и инструменты развёртывания ПО для AI Lab, в том числе внутри Ubuntu VM на Windows/VMware? Почему проектный Docker Compose не конкурирует с Dev Containers и как различать роль Ansible, Compose, VM и модуль AI Lab?

**Дата источников:** 2026-10-22. **Статус:** `EXPLORATORY / NOT AN ADR`. **Метод:** изучение первичной документации Compose Specification, Docker, Dev Containers Specification, systemd, Ansible, cloud-init, Vagrant, Terraform/OpenTofu, Kubernetes и руководства n8n; сверка с принятым `ai-lab/main` (`8584437`). Это **документационное исследование и архитектурная интерпретация**, а не измерение производительности, безопасности или развёртывание на `lab-test`.

## 1. Problem — исправление неверной предпосылки

Неправильно утверждать: «долгоживущий сервис → Docker Compose; программа одного проекта → Dev Container/Dockerfile». **Количество проектов, длительность работы процесса и технология упаковки не определяют друг друга.** Compose Specification определяет *набор связанных контейнерных сервисов*, а официальная документация прямо предусматривает отдельные экземпляры на одного разработчика/ветку/проект и использование на одном сервере в production [S1–S3]. Dev Containers используют Compose для запуска нескольких сервисов и подключения к выбранному контейнеру [S4–S5]. Dockerfile определяет **сборку образа**, а не конкурирующий с Compose механизм управления несколькими запущенными сервисами [S6].

**Правильная задача:** независимо решить, что запускается, где это запускается, кто владеет экземпляром и управляет его жизненным циклом, какая конфигурация нужна разработчику, и нужна ли отдельная граница доверия.

## 2. Scope — словарь независимых измерений

| Измерение | Вопрос | Возможные ответы (не исчерпывают варианты) |
| --- | --- | --- |
| **Placement / compute boundary** | На каком вычислительном узле? | Windows/physical host, Ubuntu VM, отдельная VM, удалённый Linux-сервер, кластер |
| **Execution isolation** | В какой среде выполняется процесс? | native Linux process, Linux app container (общий kernel), отдельная VM (собственный kernel), специализированная песочница |
| **Artifact / packaging** | Что распространяется/собирается? | APT package, бинарник, OCI image, source tree, Dockerfile как рецепт образа |
| **Lifecycle controller** | Кто управляет запуском и остановкой? | shell/оператор, systemd, Docker Engine + Compose, Podman + Quadlet, Kubernetes |
| **Configuration/provisioning** | Кто подготавливает ОС и зависимости? | bootstrap/cloud-init, Ansible, пакетный менеджер, инструменты IaC/API, образ |
| **Ownership / sharing** | Кому принадлежит конкретный экземпляр? | OS/platform, один проект, команда, множество проектов |
| **Workspace ergonomics** | Где удобно разрабатывать? | host shell/IDE, SSH, Dev Container поверх контейнера/Compose |
| **Data/trust/security** | Что нельзя потерять/открыть/смешать? | private volumes, secrets, сеть/порты, backup, роли, отдельная VM |

Эти признаки образуют **координаты одного deployment**, а не восемь обязательных архитектурных слоёв/каталогов. `Service` — процесс/логическая услуга; `Compose service` — декларация исполняемого контейнерного сервиса; `Compose project` — группа сервисов и управляемых ресурсов, объединённая именем [S1–S3]. «Host» относительно: Windows — host гипервизора, Ubuntu VM — **guest и одновременно host Docker Engine**.

**Нормальный путь на текущем AI Lab:**

```text
Windows physical host
  └── VMware hypervisor
      ├── Ubuntu "lab" VM     (reference/dev)
      │   ├── native OS processes (systemd; Git, proxy, Docker Engine)
      │   ├── Docker Engine
      │   │   ├── Compose project A: service + db + queue (one research project)
      │   │   └── Compose project B: independent service (another project)
      │   └── optional host tools (e.g., Codex CLI)
      └── Ubuntu "lab-test" VM (independent infrastructure test baseline)
```

Это схема возможного размещения, **не заявление**, что projects A/B уже развёрнуты. На практике разделение Compose проектов — namespace ресурсов Docker, **не безопасность уровня гипервизора** [S3, S10].

## 3. Alternatives — кто за что отвечает

| Механизм | Управляемый объект / граница | Хорошая задача | Не является |
| --- | --- | --- | --- |
| **VM/VMware, Vagrant** | Виртуальная машина и её сеть/диски; Vagrant описывает и запускает окружения на провайдере [S11] | отдельная ОС, сильнее отделённая зона доверия, целый воспроизводимый multi-VM стенд | автоматической системой приложения внутри VM |
| **cloud-init** | Первичная конфигурация гостевой ОС, когда VM/cloud image его поддерживает [S12] | первичная инициализация машины, network/SSH/users/packages | гипервизором или приложенческим runtime |
| **Terraform/OpenTofu + provider** | VM/сетевые/дисковые/API-ресурсы через инфраструктурные API [S13] | повторяемое создание/изменение множества инфраструктурных ресурсов | процессным менеджером Linux |
| **Ansible** | Конфигурация локальной или удалённой ОС, сервисов и пакетов через playbooks [S14] | привести хост к нужному состоянию; управлять native сервисами или вызвать другой runtime | обязательным способом запуска каждой программы |
| **systemd** | native Linux services, user/system units, process supervision [S15] | `dockerd`, нативный proxy/service/daemon, reboot/restart | контейнерным форматом или сборщиком Docker image |
| **Dockerfile + Build** | рецепт OCI/Docker образа [S6] | зависимости runtime/build для **одного образа** | менеджером нескольких контейнерных сервисов |
| **Docker Engine/Compose** | контейнеры, сервисы, volumes, networks **одного Compose project** [S1–S3] | один многоcервисный проект; dev/test/prod на одном Docker host | VM boundary, IDE environment metadata, auto multi-host scheduler |
| **Dev Containers** | *development workspace metadata* (`devcontainer.json`), подключение к контейнеру и запуск нужных Compose services [S4–S5] | редактор, язык, extensions/features, одинаковое dev workspace | заменой Dockerfile или Compose |
| **Podman + Quadlet** | контейнеры/volumes с systemd units [S16] | standalone host/container service при предпочтении Podman/systemd | необходимым дополнительным слоем поверх уже принятого Docker |
| **Kubernetes** | декларативное управление workloads в кластере [S17] | cluster reconciliation, scheduling, replicas, rolling deployments по реальной потребности | обязательным шагом после нескольких Compose projects |

Инструменты могут **комбинироваться**: VM → cloud-init/Ansible → systemd запускает Docker Engine → Compose поднимает приложение → Dev Container подключает разработчика к его сервису.

**Важно:** Ansible не обязан быть «только для CLI», Compose не обязан быть «только для общих сервисов», а runtime-хост может обслуживать множество независимых Compose projects.

## 4. Comparison — реальные границы выбора

### A. Отдельный проект, несколько сервисов — Compose является естественным выбором

Один Git-репозиторий проекта может содержать API, PostgreSQL и Redis как **один Compose project**. Compose задаёт сервисы, внутренние сети, volumes, readiness, профили; `docker compose up/down` действует в рамках этого project [S1–S3]. Сервис может быть долговременным или временным; проектный статус здесь ничего не запрещает.

- `Dockerfile` — как собрать контейнер с API.
- `compose.yaml` — как совместно запустить API, БД, очередь и сети.
- `.devcontainer/devcontainer.json` — **опционально**: в каком из этих контейнеров открывать IDE/CLI и какие инструменты разработчика там нужны.
- `systemd`/Docker restart policy — способы организовать нужный режим эксплуатации; **не превращают приложение в shared platform service**.

Официальная Dev Containers Specification определяет `dockerComposeFile`, `service`, `runServices`, а VS Code прямо описывает использование существующего Compose без переписывания файла [S4–S5]. Docker Compose также умеет overlays/include/profiles и версии для dev/prod [S2, S7].

### B. Shared service или project-local instance?

Это **выбор владельца и жизненного цикла**, а не способа запуска.

| Признак | `n8n` внутри конкретного исследовательского проекта | `n8n` как разделяемая служба AI Lab |
| --- | --- | --- |
| Owner config / version | проект | оператор/платформа |
| Данные, секреты | проект/эксперимент | разделение арендаторов/доступов, общий backup |
| Обновление/удаление | проект может пересоздать/удалить свой экземпляр | изменения затрагивают потребителей и требуют их согласования |
| Механизм | **Compose допустим и естественен** | **Compose также допустим**, отдельный project и lifecycle |
| Зачем shared | часто незачем для одного потребителя | несколько реальных потребителей с требованиями к единой доступности/данным/администрированию |

Официальная инструкция n8n поддерживает **включение в существующий Compose project**. Доступные конфигурации включают SQLite (при подходящих условиях) или PostgreSQL; **не обязателен отдельный PostgreSQL для каждого случая** [S8]. Shared n8n не надо вводить, пока не определены границы доступа, данных, обновлений и recovery конкретных пользователей.

### C. Native host vs container vs VM

- **Native process + systemd** уместен для хостовых демонов и программ, тесно связанных с OS, devices, network, GUI/desktop, kernel/security policy (например, уже принятый Xray/v2rayN bootstrap, `dockerd`). Ansible может устанавливать/конфигурировать эти программы, но их процессы затем supervises `systemd` или пользовательская сессия. Пользовательский CLI не обязан быть systemd service.
- **Контейнер/Compose** уместен для сервисов с готовым образом, отдельными зависимостями, повторяемыми конфигурациями и project-scoped data. Один проект может иметь 1 или 10 сервисов. Контейнеры одного Docker host используют общий Linux kernel; Docker access/socket и bind mounts могут размывать границы [S9–S10].
- **Отдельная VM** уместна при другом OS/kernel, необходимости отдельной настройки ядра/сети, сильнее изолированной зоне риска или полном clean-reset стенде. Несколько Compose projects в одной VM **не равны** нескольким VM по безопасности [S10].
- **Kubernetes/cluster orchestration** требуется по проблеме распределённых узлов, replica scheduling/availability/rollout, а не потому, что в одном проекте 3–5 контейнеров [S17]. Не является текущей необходимостью `ai-lab/main`.

### D. Где фактически нужен Codex?

Возможные модели для **одного и того же продукта**:
1. **Ubuntu host-user CLI**: работает в пользовательской сессии и управляет файлами Git-проекта, установка на host при обоснованном повторном использовании, например через Ansible.
2. **Project-specific development container**: CLI и зависимости внутри workspace образа, если нужна изоляция версии/toolchain. Тогда важно отдельно проектировать права на рабочее дерево, sandbox, аутентификацию и отсутствие Docker socket.
3. **Отдельная VM / sandbox**: при повышенном риске выполнения недоверенного кода или несовместимости sandbox с хостом; VM становится границей, поверх которой возможны и Compose, и Dev Container.

**Никакой универсальной таблицы «Codex → Ansible» нет.** Ранее принятые findings по AppArmor относятся к конкретному Ubuntu/VMware эксперимента, не доказывают новую host role.

## 5. Applicability — как использовать это в AI Lab

**Проверенное в `main`:** host Windows + Ubuntu 24.04 Desktop VMware; базовый S0; SSH S1; Docker Engine/Compose S1-D; optional local Ansible и `ripgrep` lifecycle (PR #15); disposable Postgres test fixture restore (PR #20). **В `main` нет рабочего n8n, переиспользуемого Dev Container окружения, общего секретного сервиса или выбранного обязательного AI runtime.** Исследовательские PR #9/#11/#13 и прошлые эксперименты не становятся автоматически принятым runtime.

**Рекомендуемая классификация одной конкретной установки — как запись параметров, а не новая иерархия:**

```text
instance: workflow-experiment-n8n
owner: independent-research-project
placement: lab Ubuntu VM          # OR dedicated Ubuntu VM when trust needs it
execution: Docker Engine containers
lifecycle: project's Compose project
configuration: versioned compose.yaml, local private .env/secret files
workspace: optional devcontainer.json referring to same Compose
state: project-scoped n8n files/DB; explicit retention and backup policy
exposure: declared ports/network; no implicit LAN trust
```

**Это иллюстрация, а не предлагаемый реализуемый `AI Lab manifest`/DSL**. Та же таблица пригодна для Codex, для сервисов в Compose и для native Ubuntu CLI.

**Правило владения кодом:** если экземпляр и его config нужны только одному исследовательскому проекту, `compose.yaml`/Dockerfile/`devcontainer.json` принадлежат **этому проекту**, даже если там 10 сервисов и круглосуточное выполнение. В `ai-lab` их можно вынести как *reusable template* лишь при реально повторённой потребности, соблюдая границы принятой стратегии: общее reusable ядро и модули AI Lab не должны быть насильно перенесены в приложения.

## 6. Выбор без бесконечных таксономий

Задавать вопросы **в таком порядке**, без автоматического вывода нового архитектурного типа:

1. **Нужна отдельная зона доверия / другой kernel / clean-VM testing?** Если да — отдельная VM; внутри неё по-прежнему возможны native/Compose.
2. **Это пользовательский CLI/host daemon или контейнеризуемое приложение?** Host daemon/GUI/network policy → native OS/user/systemd (подготовка через Ansible по потребности); приложение с образом/несколькими сервисами → Compose на выбранном Docker host.
3. **Кто независимо обновляет, удаляет, сохраняет данные?** Один проект → project-owned Compose, независимо от числа сервисов. Общий оператор и несколько потребителей → independent platform-owned Compose project/служба с политиками.
4. **Нужен ли одинаковый изолированный рабочий стол/CLI внутри container?** Опционально Dev Container, **поверх** того же Compose.
5. **Нужна ли orchestration через несколько хостов?** Лишь тогда оценить remote deployment, Vagrant/provider IaC, Kubernetes; порог — реальные операции и риски, не количество технологий.

Ни число VM, ни длительность работы сервиса, ни число проектов **не являются универсальными правилами**, которые заранее предписывают Kubernetes, Ansible или Dev Containers.

## 7. Professional applicability, license/cost and operational trade-offs

**Техническая пригодность важнее рейтингов распространённости:** здесь мы классифицируем совместно применимые стандарты, а не выбираем единственный конкурентный продукт для закупки. Поэтому несопоставимые job-market показатели не используются для псевдоранжирования разных слоёв. Compose, systemd, Ansible, Dev Containers, cloud-init и Kubernetes поддерживают разные операционные контракты [S1, S4, S12, S14, S15, S17].

- **Docker Engine (на Linux отдельно от Desktop) и Docker Compose:** upstream Apache-2.0; self-hosted engine/CLI не требуют платного SaaS. **Docker Desktop** лицензируется отдельно и может требовать оплаты в крупных организациях [S18]. Не приравнивать весь Docker stack к бесплатному Docker Desktop.
- **Ansible upstream:** GPL-3.0-or-later, локальный/open-source путь без обязательного AAP/AWX; используемые Galaxy роли/collections требуют отдельной проверки лицензий [S19].
- **Kubernetes:** Apache-2.0; лицензия open source не отменяет стоимость эксплуатации control plane, сети, storage и upgrade [S20].
- **Terraform актуальных выпусков:** Business Source License 1.1 / source-available, не просто «Open Source»; **OpenTofu:** MPL-2.0. Для создания VM/API объектов возможен выбор, но нет потребности устанавливать что-либо сейчас [S21–S22].
- **Vagrant актуальных выпусков:** BSL-1.1; необходимость поддержки конкретного VMware provider, его лицензий и стоимости нужно выяснять **при реальном выборе автоматизации VM**, а не предполагать, что провайдер всегда бесплатен [S23].
- **Dev Containers:** открытая спецификация и reference CLI, но конкретный IDE, расширения, образы и SaaS-функции имеют собственные условия; Docker Engine остаётся отдельной зависимостью [S4–S5].
- **VM vs containers:** VM расходуют отдельные OS/kernel ресурсы и требуют обновления/обслуживания, но дают иную границу изоляции; Compose упрощает многосервисное окружение, но требует понимания общих docker daemon permissions, сетей, volumes и recovery [S9–S10].
- Лицензии **n8n runtime, его платных возможностей, конкретных images и интеграций** должны проверяться отдельно при выборе его в качестве реального потребителя, независимо от лицензии Compose. Иначе ошибочно назвать весь стек OSI Open Source только по Docker.

## 8. Findings / Open Questions / Recommendations

**Подтверждено первоисточниками:**
1. Project-owned Compose — нормальный deployment для *одного* проекта с несколькими сервисами; не зависит от долговременности использования [S1–S3].
2. Dev Containers + Compose являются поддерживаемой комбинацией, Dockerfile — build artifact [S4–S6].
3. Native processes/systemd, containers/Compose и guest VM находятся **на разных уровнях изоляции и управления**, которые могут вкладываться друг в друга [S9–S15].
4. Shared vs per-project — самостоятельное решение об ownership/availability/data, а не о количестве контейнеров [S2, S3, S8].

**Инженерные выводы для AI Lab (не принятые ADR):**
- **Не создавать классы `Ansible Component` и `Compose Module` как конкурирующие типы**: это разные механизмы реализации, а «модуль» — возможная единица повторно используемой функциональности.
- Сохранить четыре принятых логических границы стратегии — Infrastructure Core, подключаемые модули, шаблоны сред и самостоятельные проекты. «Сценарий» — цель/эксперимент проекта, не упаковка приложения.
- **Для первого независимого проекта:** его собственный Compose/Dev Container файлы допустимы и обычно проще общей службы; выделение reusable template обосновывать фактическим повторным использованием.
- Не добавлять Vagrant, Terraform/OpenTofu, Kubernetes, Podman Quadlet, DevPod, оркестратор или GUI-каталог в S2 без установленного пробела. Предлагаемая классификация **не изменяет принятую D-012** о Ansible для новых optional host-managed компонентов.

**Открытые вопросы:** требуется ли проекту совместная эксплуатация n8n между разными пользователями; чьи secrets/state/backups и upgrade window; каков уровень доверия запускаемого агентами кода; нужны ли отдельные VM для двух потребителей; кто управляет гипервизором; нужно ли переносить один и тот же project runtime на другие хосты. Ответы зависят от **первого реального потребителя**, отсутствующего в current `main`.

**Минимальная следующая проверка — проектирование, не новая установка:** выбрать существующую исследовательскую задачу и заполнить `owner, placement, isolation, execution/lifecycle, state, trust` (шесть строк). Проверить, что обычный project-owned Compose покрывает зависимости; `devcontainer.json` добавлять только если нужен рабочий workspace; отдельную VM — при реальной границе доверия. **Не требовать доказательства зрелых функций платформы или запуска третьего «пилота» без измеримого риска.**

**Статус:** исследование не выбирает n8n/Codex как обязательный сервис, не предлагает реализации и **не меняет** `strategy.md`, `state.md`, `roadmap.md` или `decisions.md`.

## 9. Sources (upstream, accessed 2026-10-22)

- **S1** Compose Spec — [application model](https://compose-spec.github.io/compose-spec/02-model.html).
- **S2** Docker — [Compose model](https://docs.docker.com/compose/intro/compose-application-model/), [project names and isolation](https://docs.docker.com/compose/how-tos/project-name/), [production](https://docs.docker.com/compose/how-tos/production/).
- **S3** Docker — [project networking](https://docs.docker.com/compose/how-tos/networking/).
- **S4** Dev Containers — [Dev Container Specification](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-reference.md) and [Compose-specific JSON fields](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainerjson-reference.md).
- **S5** VS Code — [Compose-based Dev Containers](https://code.visualstudio.com/docs/devcontainers/create-dev-container).
- **S6** Docker — [Dockerfile image build](https://docs.docker.com/build/concepts/dockerfile/).
- **S7** Docker — [multiple Compose files](https://docs.docker.com/compose/how-tos/multiple-compose-files).
- **S8** n8n — [official Compose deployment](https://github.com/n8n-io/n8n-docs/blob/main/docs/deploy/host-n8n/install-options/install-using-docker-compose.md) (note vendor versions and license).
- **S9** Docker — [Engine isolation, namespaces, daemon security](https://docs.docker.com/engine/security/).
- **S10** Microsoft — [containers vs virtual machines](https://learn.microsoft.com/en-us/virtualization/windowscontainers/about/containers-vs-vm).
- **S11** Vagrant — [multi-machine](https://developer.hashicorp.com/vagrant/docs/multi-machine) and [provisioning](https://docs.hashicorp.com/vagrant/docs/provisioning).
- **S12** Canonical — [cloud-init documentation](https://docs.cloud-init.io/en/latest/).
- **S13** HashiCorp — [Terraform on-prem/cloud resource provisioning](https://developer.hashicorp.com/terraform/intro).
- **S14** Ansible — [Introduction](https://docs.ansible.com/projects/ansible/latest/getting_started/introduction.html).
- **S15** systemd — [service unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html).
- **S16** Podman — [Quadlet / systemd units](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html).
- **S17** Kubernetes — [Deployment controllers](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).
- **S18** Docker — [Engine license](https://docs.docker.com/engine/) and [separate Desktop subscription terms](https://docs.docker.com/subscription-billing/desktop-license).
- **S19** Ansible — [upstream license](https://github.com/ansible/ansible).
- **S20** Kubernetes — [upstream license](https://github.com/kubernetes/kubernetes).
- **S21** Terraform — [upstream BSL-1.1 license](https://github.com/hashicorp/terraform/blob/main/LICENSE).
- **S22** OpenTofu — [upstream MPL-2.0 license](https://github.com/opentofu/opentofu/blob/main/LICENSE).
- **S23** Vagrant — [current BSL-1.1 metadata](https://github.com/hashicorp/vagrant/blob/main/vagrant.gemspec).

**Ограничение:** официальные документы подтверждают *механизмы* и лицензии по указанной дате, но не гарантируют, что конкретные VM, secrets, HA, безопасности сети или multi-host сценарии выдержат требования AI Lab. Инженерные предпочтения выше — интерпретация, а не якобы пройденные `lab-test` испытания.
