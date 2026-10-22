# Опциональные компоненты и воспроизводимые окружения AI Lab: управление без собственной платформы

> **Исследовательский вопрос:** как оператору и AI-агенту выбирать, воспроизводимо применять, проверять и безопасно отключать инструменты Ubuntu VM и исследовательские окружения преимущественно штатными форматами и средствами?
>
> **Статус:** EXPLORATORY — предложение для обсуждения, **не** ADR, не принятое изменение архитектуры.
>
> **Срез:** 2026-10-22. Документация mise на момент проверки обозначает v2026.10.17, Task — v3.54.0; для остальных продуктов фиксируется дата проверки официальных документов, а не утверждается единая протестированная версия.
>
> **Метод:** read-only аудит ветки main, официальной документации и исходных репозиториев; сравнительная инженерная оценка. **Не выполнялись** установка, bench, обновления, очистка, проверка совместимости на lab-test или тестирование безопасности. Обозначения: **[Ф]** факт из первоисточника, **[А]** инженерный анализ, **[Г]** гипотеза/непроверенное свойство конкретного стенда.

## 1. Problem и Scope

**[Ф, R1–R5]** Принятая стратегия определяет сценарно-независимое Infrastructure Core, подключаемые модули, версионируемые шаблоны сред и независимые проекты. Это логические границы, не обязательные программные классы или службы. В main S0 → S1 → S1-D подтверждены оператором в определённом объёме на Ubuntu 24.04 Desktop / VMware (amd64), с ручными этапами; S2–S4 не имеют подтверждённой реализации. Существующий Makefile — компактный интерфейс к bootstrap-скриптам, а не инфраструктурный оркестратор. D-011 оставляет обычные Compose-сети по умолчанию.

**Проблема [А]:** при добавлении Codex, VS Code, n8n, SDK и исследовательских сервисов стоимость ручного применения, настройки, обновления, удаления и воспроизведения растёт. Нужны воспроизводимые *контракты желаемого состояния*, но **не обязательно единая технология** для машины, рабочего пространства и работающего приложения.

**Границы:** Ubuntu внутри VMware — целевой host AI Lab. Windows/физический компьютер — платформа виртуализации, не цель установки. Дополнительная VM — отдельный вариант изоляции; отдельные исследовательские проекты — потребители лаборатории. Никаких правок bootstrap, Makefile, state, roadmap, decisions и работающего окружения в рамках этого исследования. Изучаются *конфигурация и размещение*, а не выбор AI-моделей.

### Три независимые оси

| Ось | Вопрос | Примеры |
| --- | --- | --- |
| **Размещение** | Где выполняется компонент? | Ubuntu guest / контейнер проекта / другая VM |
| **Управление жизненным циклом** | Кто применяет, проверяет, обновляет и отключает состояние? | apt/mise/Ansible / Compose / Dev Container CLI / VMware |
| **Владение декларацией** | Где живут конфигурация и операционные доказательства? | ai-lab для общего хоста; отдельный Git-репозиторий потребителя; переиспользуемые примеры по подтверждённой потребности |

**[А]** Нельзя называть образ контейнера «модулем», а каталог Compose — «оркестратором», не определив, какой именно объект и состояние ими управляются. Слова Module / Blueprint / Environment допускаются как предметные обозначения, но **не** обосновывают собственной схемы/DSL.

### Три разных гарантийных контракта

1. **Окружение:** версии, источники артефактов, параметры, зависимости, команды применения, фактическая проверка и очистка. Git + lock/pin повышают повторяемость, но не гарантируют доступность источников, совместимость или побитовое совпадение.
2. **Данные:** отдельные тома/bind mounts, транзакционно согласованные backup, секреты шифрования, retention и успешный restore. Сохранение named volume при пересоздании контейнера ≠ backup.
3. **Работающий сервис:** порядок старта, readiness/health, сеть, доступ, миграции схемы, наблюдаемость, восстановление после reboot и после аварии. Docker healthy ≠ бизнес-операция успешна.

## 2. Alternatives — классы решений, вход и результат

| Класс | Инструменты | Вход → выход / ответственность | Граница |
| --- | --- | --- | --- |
| Bootstrap и управление Ubuntu | существующие Bash + APT; **mise bootstrap**; **Ansible** | Объявления пакетов/файлов/сервисов + права → состояние гостевой ОС | Не заменяют резервное копирование и изоляцию исследовательского процесса |
| CLI/runtime инструментов | **mise [tools]**, lockfile; альтернативно стандартный APT | Версии инструментов → исполнимые runtime в user/system scope | Не эквивалент настройке kernel/AppArmor или полноценному lifecycle ОС |
| Запуск контейнерных приложений | **Docker Compose** | YAML + образы + inputs → сервисы, сети, mounts | Не гарантирует durable backup, restore и security policy |
| Рабочая среда проекта | **Dev Containers Spec**, devcontainer CLI, **DevPod** | devcontainer.json (+ Dockerfile/Compose/Features) → workspace | Не является универсальным менеджером host software или долгоживущих сервисов |
| Операторский вход | существующий **Make**, альтернативно **Taskfile** или mise tasks | Имена задач/аргументы → вызов других систем | Команда «install» сама по себе не задаёт желаемое состояние |
| Декларативный пользовательский стек | **Nix + Home Manager** | Nix expression/flakes/lock → поколения пользовательской среды | Добавляет отдельный package store/экосистему на существующую APT-VM |
| Контрольная плоскость/каталог | DevPod как workspace tool; Coder/Coolify/Komodo/Portainer из R6 | Шаблоны + control plane → централизованные workspace/deployment | Дополнительные состояния, зависимости, операционная цена; не требуются априори |
| Более сильная изоляция | отдельная VMware VM | Готовая базовая VM/снимок → независимая ОС/ядро и диск | Выше расходы и отдельная воспроизводимость для каждой VM |

**[А]** Это не восемь взаимозаменяемых платформ: выбор host provisioner не заменяет Compose, а удобный task runner не снимает требования к жизненному циклу.

## 3. Важное уточнение: mise в октябре 2026

**[Ф, F1–F7]** В официальной документации mise v2026.10.17 существует не только менеджер версий и задач, но и **mise bootstrap**: пакеты (включая apt и сторонние APT sources с проверкой fingerprint), system files/directories, сервисы, Linux users/groups, firewall, Compose, репозитории, пользовательские конфигурации, секретные входы и команды plan/status/apply. Действия bootstrap выполняются **явно**, а не автоматически при чтении конфига.

**[Ф, F2]** Machine modules — файлы вида mise.codex.toml или config.codex.toml, подключаемые через **config environments**. В локальном miserc.local.toml можно выбрать список env; разовый запуск возможен через -E. Несколько модулей комбинируются; конфликтующие ключи разрешаются порядком среды, поэтому пересечения требуют ревью. Plan JSON включает происхождение ресурсов. Это штатный вариант «опционального состава» *без собственного каталога и DSL*.

**[Ф, F3–F5]** Есть отдельные границы, которые нельзя замалчивать:
- mise bootstrap unapply удаляет управляемые файлы, директории (только пустые), user services и dotfiles; **не удаляет APT-пакеты, исходные репозитории, Compose-проекты, accounts, system services и firewall state автоматически**. Изменённые вручную ресурсы защищены, если не применить force. Конфиг модуля нужно сохранять до cleanup.
- Для apt удаление записи **не удаляет пакет**, не удаляет подключённый APT source и не гарантирует возможность установить старую pinned версию, если её уже нет в репозитории. Удаление/очистка apt и sources — явные управляемые операции.
- Для Compose mise поддерживает state running/stopped/absent, status/dry-run, config-hash drift, health и зависимость от пакета/файла/сервиса. Для удаления нужно **сначала** задать state absent и применить, а уже потом удалить декларацию. down_volumes уничтожает тома и по умолчанию false.

**[Ф, F6–F7]** mise.lock фиксирует разрешённые версии/артефакты инструментов (с платформенными границами); это **не** offline-репозиторий или lock-файл состояния всей Ubuntu. Задачи mise выполняются с контекстом инструментов, могут иметь свои tools/env/dependencies; bootstrap task запускается при каждом bootstrap и должен сам быть безопасным при повторе. Для root-операций mise использует sudo/run0/doas по настройке; наличие привилегий не означает безопасность произвольного конфига. Требуется доверенная конфигурация.

**Вывод [А]:** прежний бинарный выбор «mise только для языков, Ansible — для хоста» **устарел**. mise становится серьёзным кандидатом на небольшой **single-host optional provisioning**. Однако документированные частичный unapply, новая по времени функциональность и пересечение с принятыми Bash/Compose не позволяют назвать его автоматически выбранным инструментом или доказанно надёжным в AI Lab.

## 4. Comparison — lifecycle на одинаковых критериях

Обозначения: **В** — штатная сильная поддержка для *своего объекта*; **Ч** — частично/при дисциплине автора; **Н** — вне зоны ответственности. Матрица отражает документированные механизмы и инженерную применимость, **не результаты lab-test**.

| Критерий | Bash/APT + Make | mise bootstrap + tools | Ansible roles/playbooks | Compose | Dev Containers/CLI | DevPod | Taskfile | Nix/Home Manager |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. Декларация установки | Ч | В | В | В (сервис) | В (workspace) | В (через spec) | Н | В |
| 2. Опциональный выбор/группы | Ч (условия/цели) | В (env modules) | В (roles/tags) | В (profiles/выбор сервисов) | Ч (Features/отдельные spec) | Ч (workspaces/providers) | В (задачи) | В (конфигурация) |
| 3. Зависимости | Ч | В (инструменты/ресурсы/задачи; неполный граф) | В (roles/order/modules) | В (внутри проекта) | В (image/features/Compose) | Ч (provider+spec) | В (задачи) | В (пакеты) |
| 4. Повторный запуск / convergence | Ч (нужно писать) | В/Ч (управляемые секции; hooks вручную) | В/Ч (модули; shell-команды вручную) | В/Ч (сверка Compose; не БД) | Ч (rebuild) | Ч (workspace lifecycle) | Ч (status/guards) | В (декларация) |
| 5. Версии / обновления | Ч (APT/manual) | В для tools, Ч для APT | В/Ч (pins/репозитории) | Ч (tags/digests; обновление явное) | Ч (base digest/Features pins) | Ч (подчинён spec) | Н | В (lock/generations) |
| 6. Состояние / verification | Ч (скрипты) | В для managed state, Ч для поведения | В/Ч (check/diff + checks) | Ч (config/ps/health + smoke) | Ч (CLI + тест проекта) | Ч (workspace status) | Ч (только task guards) | Ч (поколения; сервисы отдельно) |
| 7. Удаление / остатки | Ч | **Ч** (важные исключения) | Ч/В (явные absent/cleanup play) | Ч (down; volumes и bind отдельно) | Ч (контейнер vs mounts) | Ч (delete по provider) | Н | Ч/В (поколения; GC отдельно) |
| 8. Clean-VM reproducibility | Ч | Ч (baseline, pins, network) | Ч (baseline, pins, network) | Ч (после Docker) | Ч (после Docker) | Ч (после provider) | Н | В/Ч (Nix scope, external inputs) |
| 9. Секреты / привилегии | Ч (ручной контроль) | Ч (inputs, sudo, policy) | Ч (Vault/no_log/become) | Ч (service secrets, Docker root risk) | Ч (mount/env/Feature trust) | Ч (provider permissions) | Ч (shell/env) | Ч (секреты отдельно) |
| 10. Оператор / агент | В для существующих целей | В (list/plan/status/apply JSON) | Ч (playbooks/tags/check) | В (CLI/config/ps) | В (CLI/spec) | В (CLI) | В (namespaces/list) | Ч (Nix DSL) |
| 11. Накладные расходы | **Низкие до роста** | **Средние** (новый bootstrap runtime) | **Средние/высокие** (роль, Python, тесты) | **Низкие** (уже установлен) | **Низкие/средние** | **Средние** (новый provider/runtime) | **Низкие/средние** (новая точка входа) | **Высокие** при частичной миграции Ubuntu |

**Пояснения [Ф/А]:**
- **Ansible [F8–F10]:** roles, role dependencies и tags структурируют пакетные сценарии; ansible.builtin.apt поддерживает state=absent, purge/autoremove. Check/diff — симуляция только для поддерживающих её модулей; shell/command и зависимости от промежуточных результатов требуют проверки. Ansible collections — механизм дистрибуции roles/plugins, а не обязательный слой для нескольких локальных ролей. Для одной Ubuntu VM используем local connection, если выбран Ansible, не придумываем SSH-контроллер.
- **Compose [F11–F14]:** profiles включают сервисы в *одном Compose application*, depends_on задаёт запуск зависимостей, но это не общий межпроектный dependency manager. Compose include/merge дают повторное использование, но merge имеет правила порядка и относительных путей. Раздельный project name уменьшает коллизии и blast radius. docker compose config -q проверяет конфигурацию, но не эксплуатационные инварианты.
- **Dev Containers [F15–F17]:** devcontainer.json, Features, Dockerfile и Docker Compose описывают рабочий контейнер; reference CLI поддерживает up/build/exec/read-configuration. Стандарт разрабатывает **workspace**, не весь production deployment. DevPod — CLI/provider над этим стандартом; добавляет управление экземплярами и может удалить VM/container по provider, что требует проверки persistence policy.
- **Task [F18]:** includes/namespaces и list дают масштабируемые имена; status и deps помогают исполнять скрипты, но не заменяют проверку декларативного состояния. Сменять имеющийся Make только ради сокращения числа строк — недостаточная причина.
- **Nix/Home Manager [F19]:** поколения, переключение/rollback и пользовательские пакеты дают более строгую модель инструментов; на принятой Ubuntu 24.04 добавляется вторая package/runtime модель, а systemd/AppArmor/apt остаются отдельной работой. Не оправдано как первый шаг одного стенда.

## 5. Модели размещения и ownership

### A. Host-managed (Ubuntu VM)

**Назначение:** общие инструменты, доступные из GNOME/терминала, и настройки ОС, влияющие на kernel/security/daemon. **Вход:** подписанные package sources, версия, права, policies, пользовательская конфигурация. **Выход:** установленный и диагностируемый компонент в Ubuntu.

**[А]** Системные GUI-программы и AppArmor — естественные host-managed объекты. Глобальные SDK и npm-пакеты требуют обоснования: они увеличивают общий mutable state и могут конфликтовать между экспериментами. Для host операций важны управление root-правами, версиями источников, проверка фактической политики и явный teardown. Установка cli в HOME не делает его sandbox независимым от ядра.

**Реалистичные альтернативы:** (1) сохранить небольшой Bash/APT install/verify при 1–2 host options; (2) mise machine modules при росте числа независимых host options; (3) Ansible, когда множественные file/service/policy changes, удаление или check/diff важнее простоты. Не включать сразу mise и Ansible для одних и тех же пакетов/файлов.

### B. Project-managed / isolated containers

**Назначение:** зависимости конкретного исследования, SDK, CI/workspace tools и контейнерные сервисы. **Вход:** Git + lockfiles + devcontainer.json/Dockerfile/Compose + секреты вне Git. **Выход:** отделяемое рабочее пространство и/или сервисный стек.

**[А]** Для процесса разработки — Dev Containers; для работающего сервиса — Compose. Они могут сосуществовать: devcontainer ссылается на Compose и открывает service/workspace внутри стека. DevPod не обязателен, если reference CLI или VS Code уже обеспечивает нужный workflow. Сервисы с долгоживущими данными следует эксплуатировать отдельно от уничтожаемого workspace, если жизненные циклы отличаются.

**Ограничения:** Docker socket/control доступа даёт большие полномочия; изоляция контейнера — не security boundary для недоверенного root/privileged workload. Исследовательские зависимости в контейнере не требуют host-модификаций, пока не нужны драйверы, kernel hooks, устройства или daemon integration.

### C. Separate VM

**Назначение:** изоляция несовместимых системных политик, root-sensitive/runtime компонентов или потенциально опасных экспериментов. **Вход:** версионированная базовая VM/снимок, bootstrap, ограничения ресурсов, network policy. **Выход:** независимо удаляемая ОС.

**[А]** Оправдано при конфликтующих конфигурациях AppArmor/namespace/драйверов, ином уровне доверия, требованиях к ядру или проверке чистого rollback. Контейнер предпочтительнее для обычных SDK/сервисов. VMware snapshot полезен как тестовый reset, **не заменяет off-VM backup и восстановление данных**. Двойная иерархия VM + контейнеры должна иметь реальную причину.

## 6. Применение к четырём компонентам

| Пример | Размещение | Механизм / файлы | Выбор и жизненный цикл | Критическая проверка |
| --- | --- | --- | --- | --- |
| **Codex CLI** | **Host** по заданному сценарию; внутри Dev Container — отдельный вариант для проекта | Версионируемый CLI и Ubuntu sandbox prerequisites. Сначала Bash/APT/официальный пакетный путь; mise для runtime/tool при пригодном backend; Ansible/mise bootstrap при повторяющихся policy changes | Опциональный host setup; CLI updates отдельно от sandbox policy. Root-подготовка отделена от запуска агента | codex version, непривилегированный bwrap/userns smoke, фактический denied write/network внутри песочницы, отсутствие глобального ослабления AppArmor |
| **VS Code GUI** | **Host** Ubuntu GNOME | Официальный Microsoft APT repo, Signed-By key, пакет code; настройки/extensions явно | Опциональный APT package; возможно mise APT module или Ansible role; upgrade из доверенного repo; uninstall отдельно | version/GUI launch, plugins/config, источник пакета, update и cleanup |
| **n8n** | **Compose** в Ubuntu, при более сильной границе — отдельная VM | compose.yaml, закреплённый image, persistent /home/node/.n8n, БД при необходимости, секреты и ключ шифрования | docker compose -p ... up/down/ps; не соединять с жизненным циклом ephemeral devcontainer | readiness + создание workflow/credential + сохранение после recreate/reboot; **backup/restore БД, пользовательского состояния и encryption key** |
| **Исследовательский проект** | **Dev Container + Compose** с зависимостями; VM только при особом риске | devcontainer.json, Dockerfile/Features, language locks, compose project | devcontainer CLI либо DevPod, Compose per-project, независимые репозитории и project names | clean project up, smoke, repeat, isolated deps, teardown без потери общего сервиса/данных |

**Codex security [Ф, F20–F22]:** текущая реализация Codex Linux sandbox использует bubblewrap и namespaces/seccomp; на Ubuntu AppArmor может запрещать создание user namespace. Нельзя считать установку npm/CLI достаточной проверкой. Ошибка AppArmor **не является основанием глобально отключить защиту**: targeted policy и проверка действующей изоляции безопаснее, чем отключение системных sysctl. Конкретная совместимость версии Codex, системного bwrap, Ubuntu 24.04 и имеющихся AppArmor profiles — **[Г] локальная**, а не гарантированная документацией. Пользовательские GitHub issue — сигналы о failure modes, не доказательство для lab-test.

**VS Code [Ф, F23]:** официальный APT repository и пакет существуют, но выбор стороннего источника кода должен явно проверять key/fingerprint/apt provenance. **[А]** Неправильно помещать GUI-редактор в devcontainer, если требование — локальное GNOME-приложение в Ubuntu.

**n8n [Ф, F24–F26]:** официальная документация рекомендует Compose и отдельно предупреждает о необходимости эксплуатации. Даже если использовать внешнюю PostgreSQL, следует сохранять n8n user state и ключ шифрования, иначе доступ к credentials может быть потерян. **[А]** Port publishing по умолчанию ограничить loopback при локальном эксперименте; LAN exposure оценивать отдельно, не заявлять сеть изолированной без теста. Не применять down -v без подтверждённого намерения уничтожить данные.

## 7. Как организовать выбор при десятках компонентов без собственного интерфейса

**[А, рекомендация без принятия ADR]** Не хранить всю номенклатуру в корневом Makefile. Единый вход — **документация + стандартные CLI, которыми уже управляют ресурсы**, с несколькими стабильными командами-диспетчерами для bootstrap и проверок при необходимости:

- **Host:** маленькие независимые декларации, сгруппированные штатными mise **config environments** (если mise выбран) или Ansible roles/tags (если он выбран). Локальный выбор состава хранится **вне Git**; повторяемая комплектация требует версионированного примера/зафиксированного перечня выбранных env, а не только личного miserc.local.toml.
- **Container services:** независимый compose.yaml на сервис/продукт или ограниченные profiles внутри *одного* связанного стека; для переиспользования — штатные include/override с проверкой docker compose config. **Не** смешивать все независимые исследования в один гигантский Compose project: профили не являются межпроектной системой.
- **Workspace:** собственный .devcontainer/devcontainer.json рядом с независимым исследовательским проектом; CLI выбора — devcontainer (или DevPod при полезности provider lifecycle).
- **Operator/agent:** показывать стандартный список через mise tasks ls / mise bootstrap plan (при mise), ansible-playbook --list-tags (при Ansible), docker compose config --profiles/--services и make help в нынешнем baseline. Это разные границы — не требуется единое API поверх всех.
- **Composition:** небольшой version-controlled документ «состав среды» может содержать командные инструкции и выбранные native config files без нового машиночитаемого формата. Если появится 2+ повторяемых комплектации, сравнить именно фактическую стоимость исполнения и восстановления. Собственная модель Blueprint не нужна, пока штатные декларации достаточны.

### Иллюстрация механики, а не предлагаемый внедряемый файл

Если выбран mise для host options, официально поддерживаемая идея — раздельные файлы machine modules и список сред:

~~~toml
# Пример, схематично. Не запускался на lab-test.
# ~/.config/mise/miserc.local.toml (НЕ коммитить как общую комплектацию)
env = ["codex", "vscode"]
~~~

~~~sh
# Диагностика/предпросмотр; только пример синтаксиса из официальной модели mise
mise bootstrap plan
mise bootstrap status
mise bootstrap --dry-run

# Действие только после отдельного решения и тестового плана:
# mise bootstrap
~~~

Для **чистого Make + Compose baseline** нового CLI вообще не требуется: оператор переходит в директорию нужного проекта и использует стандартные docker compose config/ps/up/down. Это **осознанный более простой вариант**, а не временный технический долг.

### Три варианта для S2 — стоимость и точка перехода

| Вариант | Новые обязательные зависимости | Цена разработки и поддержки (относительная) | Условие выбора |
| --- | --- | --- | --- |
| **V0: существующие Make/Bash + Compose** | **Нет** | **Низкая** пока сценариев немного; возрастает при host-state/cleanup | **Основной baseline** для одного S2 сервиса |
| **V1: mise для host options; Compose напрямую для сервисов** | mise и его доверенная конфигурация | **Средняя**; меньше собственных host scripts, но новая семантика и частичный cleanup | Несколько независимых host options, измеримое снижение повторяющейся логики и успешная проба clean-VM |
| **V2: Ansible host roles; Compose напрямую для сервисов** | ansible-core/collections по необходимости | **Средняя–высокая**; лучше для подробных OS policies/absent/check | Несколько policy-heavy задач и реальная потребность в управлении system drift |

**[А]** V1 и V2 — **альтернативы управления одним host scope**, не рекомендуемая совместная установка. Упрощение одного интерфейса нельзя покупать ценой двух независимых владельцев одного ресурса. V0 не предполагает написания общего модуля-раннера: новые сценарии используют собственные стандартные команды.

## 8. Что изменилось относительно platform-landscape [R6]

| Было исследовано ранее | Что добавлено здесь | Следствие |
| --- | --- | --- |
| Системы уровня Workbench/DevPod/Coder/Komodo/Coolify, их control plane и template catalogs | Границы **host packaging/optional selection** (mise modules и Ansible roles) | Выбор модулей host можно организовать вообще без deployment platform |
| Рекомендация начать Compose baseline на S2 | Конкретные profiles/include, project-scoped ownership, версии/удаление/backup и разделение service vs data | **Подтверждает**, а не отменяет Compose-first для сервисов |
| Dev Containers/DevPod как проектная среда | Стандарт devcontainer.json, Features и самостоятельный CLI без DevPod | DevPod **не обязательная зависимость** для воспроизводимого workspace |
| Reusable templates остаются логическими артефактами AI Lab | Состав окружения может опираться на mise env + compose.yaml + devcontainer.json **без Blueprint DSL** | Возможное уменьшение собственного IaC-кода, не отказ от принятой логической модели |
| Риск drift и утраты данных | Частичный mise unapply, apt/source cleanup, Compose down -v, секреты ключей и executable smoke | Требует явного контракта teardown/recovery на каждый компонент |
| Host bootstrap рассматривается как внешняя предпосылка platform tools | mise bootstrap в 2026 охватывает части OS provisioning; Ansible — полноценная альтернатива | **Новая конкуренция внутри host-management**, которую landscape не анализировал |

**Противоречий с D-001, D-002, D-003, D-010, D-011 и roadmap не выявлено [А].** Смена принятого Bash bootstrap или пересмотр места хранения reusable templates **не предлагаются этим документом**. Отдельно: названия Module/Template в стратегии остаются, потому что это логические категории, а не выбор реализации. В ранее предложенном эксперименте одного HTTP-сервиса + PostgreSQL основная идея сохраняется; для вопроса **host optionality** потребуется самостоятельная маленькая проверка, если для неё возникнет конкретная потребность.

## 9. Open Questions, риски, минимальные проверки

| Приоритет | Вопрос и статус | Минимальное разрешение |
| --- | --- | --- |
| **P0** | Секреты, Docker privileges и destructive cleanup можно случайно отдать агенту без review. [А] | **До любой автоматизации действия** отделить read-only plan/status от apply/remove, задать operator approval, запретить слепые down -v, sudo и sysctl изменения |
| **P1** | Совместимость mise bootstrap v2026.10.17 с **существующими** S0/S1/S1-D пакетными источниками, прокси и правилами прав неизвестна. [Г] | Только если V1 реально нужен: один безвредный optional APT package или user file на чистом клоне; plan → apply → rerun → drift → unapply/explicit cleanup; проверить отсутствие затрагивания существующего Docker |
| **P1** | Codex sandbox / AppArmor в Ubuntu конкретной VM ещё не верифицирован. [Г] | При реализации Codex: проверить policy и sandbox в тестовой VM, без глобального отключения AppArmor; проверить негативные операции, а не только запуск codex --version |
| **P1** | Восстановление n8n/БД после потери VM/тома не покрыто одним Compose. [А] | Репрезентативный S2 spike из landscape: создать запись и credentials test fixture без реальных секретов → backup → уничтожить disposable данные → restore → API/операционный smoke |
| **P1** | Неизвестна ценность отдельного task runner/host manager при реальной частоте host changes. [Г] | Сначала измерить число неидемпотентных host scripts, объём ручных шагов и дублирования в двух настоящих компонентах; документации по возможностям tools для ответа достаточно |
| **P2** | Конфликты версий/runtime, bind mounts, порты и project names между проектами. [Г] | Два небольших независимых Compose projects в disposable среде; down одного не должен влиять на другой; инструмент не нужен до подтверждения коллизии |
| **P2** | Место хранения общего шаблона vs внешнего проекта (логическая ownership boundary). [А] | Не выбирать абстрактно: первый повторно используемый шаблон оставить по фактическому owner; пересматривать после второго реального потребителя, при смене стратегии — ADR |
| **P2** | Частичное удаление через mise может оставлять APT packages, APT sources, system services и Compose. **[Ф]** | Уже **решено документацией** [F3–F5]: не нужен spike, нужен явный teardown контракт и не обещать full uninstall |
| **P2** | Возможности Taskfile, DevPod, Home Manager vs Make/Dev Container CLI. **[Ф/А]** | Документация описывает функции; отдельный сравнительный experiment **не нужен** до запроса на недостающую возможность |

### Минимальный следующий E2E, после отдельного согласования

**Первая итерация должна проверять потребность S2, не новый инструмент.** В отдельной implementation PR:
1. Взять **один** disposable Compose service с постоянными данными, отдельным project name, explicit volumes, фиксированным image ref и локальным ограничением опубликованных портов.
2. Сохранить compose.yaml, non-secret inputs и отдельные шаги проверки, backup/restore, teardown. Проверить docker compose config -q, запуск и API smoke.
3. На lab-test из согласованного снимка: первоначальная установка → rerun → reboot → recreate → восстановление из backup после controlled data loss. Зафиксировать Git SHA/версии, все реальные команды, manual steps, PASS/FAIL.
4. Если реальный Codex/VS Code host сценарий показывает повторение OS-state логики, отдельно сравнить **одну и ту же** установку через существующий Bash и через mise machine module (либо Ansible при OS-policy сложностях). Не дублировать уже закрытые вопросами документации проверки.
5. На PR review решить: оставить V0, принять V1 или V2 для *следующей* host-итерации. Решение занести в decisions только после явного согласия.

**Критерий успеха [А]:** оператор и агент могут воспроизвести нужный *конкретный* сервис/инструмент без знания переписки, с заданными inputs, фактической проверкой и управляемыми последствиями удаления. Преимущество нового инструмента должно выражаться в уменьшении кода/ошибок/ручных операций, а не в маркетинговом списке функций.

## 10. Findings и рекомендации к решению

1. **[Ф]** mise v2026.10.17 действительно содержит machine modules, bootstrap plan/status/apply, APT sources, files/services и управление Compose. **[А]** Это наиболее содержательный *новый* кандидат на optional host management, не рассмотренный в R6. **[Г]** Его эксплуатационная надёжность на lab-test пока неизвестна.
2. **[Ф]** mise unapply/apt cleanup не обеспечивают полное симметричное удаление. **[А]** Декларация установки, owner данных и инструкция безопасного удаления — разные ответственности. Нельзя считать «отсутствует в выбранном env» равным «удалено».
3. **[Ф]** Docker Compose и Dev Containers уже предоставляют собственные декларации, профили и CLI. **[А]** Универсальная оболочка, каталог Blueprint/Module, ещё один orchestration control plane и Taskfile одновременно **не обоснованы**.
4. **[А]** Для ближайшего S2 оставить **V0: существующие Make/Bash + Compose + Git + независимые verify/recovery**, не расширять Make до «100 сервисных целей». Для выбора многочисленных *host options* рассматривать **mise** прежде Ansible **только в рамках подтверждённой потребности**; Ansible сильнее там, где нужен контроль сложного system state и симметричное absent.
5. **[А]** В проектных средах применять Dev Containers как формат, Dev Container CLI как минимальное исполнение; DevPod, Nix и дополнительные VM вводить по явным сигналам о недостающих функциях. Все обещания воспроизводимости должны иметь clean baseline и тест, не только декларацию.
6. **Статус:** выводы исследования **не приняты**; архитектура, milestone state и код main не изменяются. Практическая реализация — отдельная обсуждаемая задача.

## Источники

**Внутренние (принятый main, просмотрено 2026-10-22):**

- **[R1]** [AI Lab — AGENTS.md](../../AGENTS.md)
- **[R2]** [Стратегия](../project/strategy.md)
- **[R3]** [State](../project/state.md) и [roadmap](../project/roadmap.md)
- **[R4]** [Decisions](../project/decisions.md) (D-001, D-003, D-010, D-011)
- **[R5]** [Makefile](../../Makefile), [bootstrap runbook](../../bootstrap/README.md)
- **[R6]** [Первое исследование: platform-landscape](2026-10-22-platform-landscape.md)

**Внешние первоисточники (проверка 2026-10-22):**

- **[F1]** mise: [Bootstrap](https://mise.jdx.dev/bootstrap.html), [setup a machine](https://mise.jdx.dev/bootstrap/setup.html)
- **[F2]** mise: [Machine modules / config environments](https://mise.jdx.dev/bootstrap/modules.html)
- **[F3]** mise: [bootstrap unapply, exclusions](https://mise.jdx.dev/cli/bootstrap/unapply.html)
- **[F4]** mise: [Ubuntu apt packages, pins, APT sources, remove](https://mise.jdx.dev/bootstrap/packages/apt.html), [package prune limitation](https://mise.jdx.dev/cli/bootstrap/packages/prune.html)
- **[F5]** mise: [Docker Compose projects — desired states, drift, teardown](https://mise.jdx.dev/bootstrap/compose.html)
- **[F6]** mise: [Lockfiles](https://mise.jdx.dev/dev-tools/mise-lock.html), [system installs](https://mise.jdx.dev/dev-tools/system-installs.html)
- **[F7]** mise: [Tasks](https://mise.jdx.dev/tasks/), [task configuration](https://mise.jdx.dev/tasks/task-configuration.html), [settings and sudo](https://mise.jdx.dev/configuration/settings.html)
- **[F8]** Ansible: [Roles/dependencies](https://docs.ansible.com/projects/ansible/latest/user_guide/playbooks_reuse_roles.html), [tags](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_tags.html)
- **[F9]** Ansible: [apt module](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/apt_module.html)
- **[F10]** Ansible: [check/diff mode and limitations](https://docs.ansible.com/projects/ansible-core/devel/playbook_guide/playbooks_checkmode.html)
- **[F11]** Docker: [Compose profiles](https://docs.docker.com/compose/how-tos/profiles/), [Compose project model](https://docs.docker.com/compose/intro/compose-application-model/)
- **[F12]** Docker: [Compose include/merge](https://docs.docker.com/compose/how-tos/multiple-compose-files), [merge path rules](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/)
- **[F13]** Docker: [Compose config](https://docs.docker.com/reference/cli/docker/compose/config), [Compose down and volumes](https://docs.docker.com/reference/cli/docker/compose/down/)
- **[F14]** Docker: [Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/), [Docker Engine security](https://docs.docker.com/engine/security/)
- **[F15]** Dev Containers: [Specification/reference](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainerjson-reference.md), [Feature registry](https://containers.dev/features)
- **[F16]** Dev Containers: [Dockerfile and Compose guide](https://containers.dev/guide/dockerfile), [reference CLI](https://github.com/devcontainers/cli)
- **[F17]** DevPod: [overview/providers](https://devpod.sh/docs/what-is-devpod), [stop](https://devpod.sh/docs/developing-in-workspaces/stop-a-workspace), [delete/provider cleanup](https://devpod.sh/docs/developing-in-workspaces/delete-a-workspace)
- **[F18]** Taskfile: [includes/namespaces](https://taskfile.dev/docs/guide/includes), [guide](https://taskfile.dev/docs/guide/)
- **[F19]** Home Manager: [manual](https://nix-community.github.io/home-manager/), [release note with rollback](https://nix-community.github.io/home-manager/release-notes/rl-2511.html)
- **[F20]** OpenAI Codex: [Linux sandbox README, bwrap and seccomp](https://github.com/openai/codex/blob/main/codex-rs/linux-sandbox/README.md)
- **[F21]** OpenAI: [codex-action Linux sandbox prerequisites](https://github.com/openai/codex-action/blob/main/README.md)
- **[F22]** OpenAI Codex: [Ubuntu/AppArmor issue #15057](https://github.com/openai/codex/issues/15057) и [issue #48681 о nested bwrap warning](https://github.com/openai/codex/issues/48681) — публичные баг-репорты, не результаты AI Lab
- **[F23]** Microsoft: [VS Code installation on Ubuntu](https://code.visualstudio.com/docs/setup/linux)
- **[F24]** n8n: [Docker Compose self-hosting guide](https://docs.n8n.io/deploy/host-n8n/install-options/use-a-cloud-provider/use-docker-compose.md)
- **[F25]** n8n: [Install with Docker: сохранение .n8n, ссылка на предпочтительный Compose](https://docs.n8n.io/deploy/host-n8n/install-options/install-with-docker.md)
- **[F26]** Docker: [Volume persistence semantics](https://docs.docker.com/reference/cli/docker/compose/down/), [secrets mounts](https://docs.docker.com/compose/how-tos/use-secrets/)

**Ограничение достоверности:** все оценки сложности сравнительные; надёжность, время установки, производительность, лицензии/квоты в конкретной конфигурации, эффективность security policy и чистое удаление на lab-test **не проверялись**. Документ намеренно не содержит PASS/VERIFIED для новых компонентов и не предлагает автоматической миграции с текущего bootstrap.
