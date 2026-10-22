# Codex CLI на Ubuntu/VMware — проверенные результаты экспериментов

**Исследовательский вопрос:** что из [PR #11](https://github.com/lehater/ai-lab/pull/11) (Codex → n8n) и [PR #13](https://github.com/lehater/ai-lab/pull/13) (кандидат установки Codex) следует оставить для будущих работ AI Lab, не принимая экспериментальные установщики?

**Дата:** 2026-10-22. **Статус:** `EXPERIMENTAL FINDINGS`, не ADR. **Метод:** изучение кода и документации веток, отчётов оператора и опубликованных артефактов эксперимента. **Ограничения:** тесты выполнялись оператором на уже настроенной Ubuntu 24.04 Desktop amd64 (VMware, GNOME Wayland). Новые установщики не проверялись на чистой VM; Stage B n8n export/replay не выполнялась.

## Problem / Scope

Codex — необязательный инструмент разработчика в гостевой Ubuntu VM, а не зависимость принятого S0 → S1 → S1-D и не компонент обязательного S2 Infrastructure Core. Физический Windows — только хост виртуализации. Исторические n8n Compose, Bash-установщики Codex из PR #11 и #13, экспериментальные токены и JSON workflow **не принимаются как управляемые модули AI Lab**.

Способ организации опциональных компонентов отдельно исследован в [optional-components-lifecycle](2026-10-22-optional-components-lifecycle.md). Ansible пока лишь проверяемое направление, не принятый и не подтверждённый на lab-test стандарт.

## Findings — Codex CLI и AppArmor

1. Оператор проверил `@openai/codex@0.163.0`, `codex-cli 0.163.0` и `codex login status` с результатом `Logged in using ChatGPT`. Версия 0.163.0 — исторический pin эксперимента, **не рекомендация для новой установки**. Код установщика в PR #13 прошёл статические проверки, **но не clean-VM setup/rerun/reboot**.
2. На Ubuntu 24.04 с `kernel.apparmor_restrict_unprivileged_userns=1` при запуске агента наблюдалось `bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`. Оператор восстановил работу через Ubuntu-пакеты `apparmor-profiles`, `apparmor-utils` и штатный профиль `bwrap-userns-restrict`, загружаемый из `/usr/share/apparmor/extra-profiles/` в `/etc/apparmor.d/`. Глобальное ограничение AppArmor оставлено включённым.
3. Проверочные команды `bwrap --unshare-user --unshare-net --ro-bind / / /bin/true` и **`codex sandbox -- /bin/true`** завершились с кодом 0. Обычная интерактивная sandbox-сессия затем успешно выполняла read-only `pwd && git status --short --branch`, без обхода sandbox.
4. `codex sandbox linux /bin/true` — **ошибочная команда**: слово `linux` было интерпретировано как имя исполняемого файла (exit 101). Более ранний `codex: command not found` (exit 127) был связан с отсутствием `~/.local/bin` в `PATH`; это не доказательства неисправности sandbox.
5. Для будущей Ansible Role сохраняется принцип **fail closed**: сначала выполнить sandbox smoke; перед загрузкой профиля проверить конфликты вокруг `/usr/bin/bwrap`; не менять глобальный sysctl, не отключать AppArmor, не запускать Codex без sandbox, не выдавать Docker socket или членство в `docker` group. Отдельно проверять работу обычной интерактивной сессии.
6. Codex sandbox может ограничивать запись `.git/index.lock` даже после успешного AppArmor-исправления. Git commit следует исполнять через отдельно авторизованный операторский процесс, не расширяя привилегии агента ради удобства.

## Findings — clipboard VMware / Wayland

На `lab-test` Codex `/copy` давал корректный текст внутри Ubuntu, но при немедленном переходе из Codex в Windows вставлялось старое значение.

**Проверенный обход:** `/copy` → переключить фокус на **другое окно внутри Ubuntu** → перейти в Windows → `Ctrl+V`. Повторное копирование через редактор не нужно. Причина на уровне VMware/open-vm-tools не доказана. Xorg оператор ранее отверг из-за проблем масштабирования, разрешения и работы окон. Не вводить clipboard daemon или автоматическую синхронизацию ради этой проблемы.

Допустимый будущий GUI: **VS Code + официальное расширение Codex локально внутри Ubuntu VM**, независимо от CLI; IDE не устанавливалась и не тестировалась в PR #13. Windows VS Code/Remote-SSH не были частью выбранного сценария.

## Findings — n8n MCP

В [закрытом PR #11](https://github.com/lehater/ai-lab/pull/11) Codex подключился через instance-level MCP к временной n8n 2.44.5 (Compose, порт только `127.0.0.1:5678`), создал workflow из трёх узлов и выполнил числовое преобразование:

- При множителе 2 выполнение №1 вернуло **8** из 4 (исторический операторский отчёт).
- Прямая правка пути массива через `setNodeParameter` была отвергнута. Через `updateNodeParameters` с полным валидированным объектом параметров изменён **тот же узел**.
- Опубликованные `workflow-before.json` / `workflow-after.json` показывают тот же workflow ID, узлы и связи; изменилось только выражение множителя `×2` → `×3`. `results.json` фиксирует выполнение №2: `status=success`, input 4, output **12**. Черновик не опубликован.
- Артефакты прошли локальный JSON/структурный preflight и последующий просмотр через GitHub без обнаруженных очевидных секретов. Это не универсальная гарантия отсутствия секретов.
- **Stage B (reconstruction from Git on clean n8n volume) не выполнялась.** Продемонстрировано редактирование workflow агентом через MCP, но не переносимое восстановление n8n.
- Маленький вычислительный workflow не доказывает потребности в n8n в ядре. Compose-стенд и временные данные остаются историческим экспериментом, а не принятой установкой AI Lab.

## Comparison / applicability: что брать в новую реализацию

| Область | Требование |
| --- | --- |
| Развёртывание | Явный opt-in, пользовательский Codex; root только для отдельных APT/AppArmor-операций |
| Версии | Актуальный при реализации reviewed pin, реальная версия в тесте; не копировать без проверки старый 0.163.0 |
| Установки | Не перетирать чужой launcher или существующую несовместимую установку; повторные запуски должны быть безопасны |
| Безопасность | Не отключать global AppArmor; sandbox smoke + interactive check; запрет незапрошенного повышения привилегий |
| Секреты | Интерактивный ChatGPT login; не включать `~/.codex/auth.json`, MCP tokens и приватные конфигурации в Git |
| Эксплуатация | Независимая `verify`, restart/reboot, явное управляемое удаление только собственного состояния |
| GUI | Опциональный локальный VS Code отдельно от CLI и AppArmor |
| Приёмка | Нужен **новый** clean-baseline прогон будущей реализации с фиксацией реальных PASS/FAIL |

**Рекомендация:** не доводить самостоятельные Bash-установщики из PR #11 и #13 до статуса поддерживаемых компонентов. Если после Ansible spike Codex потребуется как host option — создать новую Role на основе этих ограничений и проверить заново. Это не решение о принятии Ansible без испытаний.

## Sources / Open questions

Основные источники — [исторический эксперимент PR #11](https://github.com/lehater/ai-lab/pull/11), его четыре Stage A evidence-файла и [кандидат Codex PR #13](https://github.com/lehater/ai-lab/pull/13) с кодом, документацией sandbox и подтверждённым clipboard workaround. Отчёты оператора и существующие JSON не заменяют повторное независимое испытание.

Внешний контекст: [OpenAI Codex](https://github.com/openai/codex), [Ubuntu AppArmor](https://ubuntu.com/security/apparmor), [VS Code Linux](https://code.visualstudio.com/docs/setup/linux). Остаются непроверенными: чистая установка новой роли, совместимость более новых Codex/Ubuntu, корректная очистка уже используемых AppArmor-профилей и реальные причины VMware clipboard lag.
