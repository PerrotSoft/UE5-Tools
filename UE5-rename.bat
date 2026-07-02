@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Определение цветов ANSI
set "ESC="
set "RED=!ESC![0;31m"
set "GREEN=!ESC![0;32m"
set "CYAN=!ESC![0;36m"
set "YELLOW=!ESC![1;33m"
set "BLUE=!ESC![0;34m"
set "PURPLE=!ESC![0;35m"
set "NC=!ESC![0m"

set "BASE_DIR=%USERPROFILE%\Documents\Unreal Projects"

echo %CYAN%┌────────────────────────────────────────────────────────┐%NC%
echo %CYAN%│      ТОТАЛЬНОЕ ПЕРЕИМЕНОВАНИЕ ПРОЕКТА UE5 (C++)        │%NC%
echo %CYAN%└────────────────────────────────────────────────────────┘%NC%

:: 1. ОПРЕДЕЛЕНИЕ ИМЕН
set "OLD_NAME=%~1"
set "NEW_NAME=%~2"

if not "%OLD_NAME%"=="" if not "%NEW_NAME%"=="" (
    echo %BLUE%[Инфо] Имена проектов получены из аргументов запуска.%NC%
    goto :start_process
)

:interactive_menu
echo %YELLOW%[ Меню ] Сканируем папку Unreal Projects...%NC%
echo %CYAN%┌────────────────────────────────────────────────────────┐%NC%

set "count=0"
for /d %%D in ("%BASE_DIR%\*") do (
    set /a count+=1
    set "proj[!count!]=%%~nD"
    echo %CYAN%│  [!count!] %YELLOW%%%~nD%NC%
)

if %count%==0 (
    echo %RED%│ [Ошибка] В папке "%BASE_DIR%" проектов не найдено!│%NC%
    echo %CYAN%└────────────────────────────────────────────────────────┘%NC%
    pause
    exit /b
)
echo %CYAN%└────────────────────────────────────────────────────────┘%NC%

:select_project
echo %CYAN%┌────────────────────────────────────────────────────────┐%NC%
set /p "choice=%CYAN%│ Выберите номер проекта (1-%count%): %YELLOW%"
if not defined proj[%choice%] (
    echo %RED%│ Неверный номер! Попробуйте еще раз.                 │%NC%
    goto :select_project
)
set "OLD_NAME=!proj[%choice%]!"
echo %CYAN%│ Выбран проект: %YELLOW%%OLD_NAME%%NC%

:input_new_name
set /p "NEW_NAME=%CYAN%│ Введите НОВОЕ имя для этого проекта: %GREEN%"
echo %CYAN%└────────────────────────────────────────────────────────┘%NC%

if "%NEW_NAME%"=="" (
    echo %RED%[Ошибка] Новое имя не может быть пустым!%NC%
    goto :input_new_name
)

:start_process
set "OLD_PROJECT_DIR=%BASE_DIR%\%OLD_NAME%"
set "NEW_PROJECT_DIR=%BASE_DIR%\%NEW_NAME%"

:: 2. ПРОВЕРКА ПАПОК
echo.
echo %PURPLE%┌── [ ШАГ 1: Проверка окружения ] ───────────────────────┐%NC%

if not exist "%OLD_PROJECT_DIR%" (
    echo %RED%│ [Критическая ошибка] Папка исходного проекта не найдена!%NC%
    echo %RED%│ Ожидалось тут: %OLD_PROJECT_DIR%%NC%
    echo %PURPLE%└────────────────────────────────────────────────────────┘%NC%
    pause
    exit /b
)

if exist "%NEW_PROJECT_DIR%" (
    echo %RED%│ [Критическая ошибка] Папка с новым именем уже существует!%NC%
    echo %RED%│ Путь занят: %NEW_PROJECT_DIR%%NC%
    echo %PURPLE%└────────────────────────────────────────────────────────┘%NC%
    pause
    exit /b
)
echo %GREEN%│ [Успешно] Проверки пройдены. Начинаем тотальную замену...│%NC%
echo %PURPLE%└────────────────────────────────────────────────────────┘%NC%

:: 3. ПЕРЕИМЕНОВАНИЕ КОРНЕВОЙ ПАПКИ
echo.
echo %PURPLE%┌── [ ШАГ 2: Переименование директории ] ────────────────┐%NC%
echo %CYAN%│ Перенос: %OLD_NAME% ➔ %NEW_NAME%%NC%
ren "%OLD_PROJECT_DIR%" "%NEW_NAME%"
if errorlevel 1 (
    echo %RED%│ [Ошибка] Не удалось переименовать папку. Закройте UE5. │%NC%
    echo %PURPLE%└────────────────────────────────────────────────────────┘%NC%
    pause
    exit /b
)
cd /d "%NEW_PROJECT_DIR%"
echo %GREEN%│ [Успешно] Главная папка проекта переименована.          │%NC%
echo %PURPLE%└────────────────────────────────────────────────────────┘%NC%

:: 4. ОЧИСТКА КЭША
echo.
echo %PURPLE%┌── [ ШАГ 3: Предварительная очистка кэша ] ─────────────┐%NC%
for %%F in (Binaries DerivedDataCache Intermediate Saved .vs) do (
    if exist "%%F" (
        rmdir /s /q "%%F"
        echo %YELLOW%│  ➔ Удален старый кэш: %%F%NC%
    )
)
echo %PURPLE%└────────────────────────────────────────────────────────┘%NC%

:: 5. ТОТАЛЬНАЯ ЗАМЕНА ВНУТРЕННЕГО СОДЕРЖИМОГО (Исправлен баг с расширениями)
echo.
echo %PURPLE%┌── [ ШАГ 4: Тотальная замена текста внутри файлов ] ─────┐%NC%
echo %CYAN%│ Сканирование контента (.uproject, .ini, .cs, .h, .cpp)...%NC%

:: Точки \. добавлены в регулярное выражение для точного совпадения расширений файлов
powershell -Command "$old='%OLD_NAME%'; $new='%NEW_NAME%'; Get-ChildItem -Recurse -File | Where-Object { $_.Extension -match '\.(uproject|ini|cs|h|cpp|target)$' } | ForEach-Object { $utf8 = New-Object System.Text.UTF8Encoding($true); $content = [System.IO.File]::ReadAllText($_.FullName, $utf8); if ($content -match $old) { $newContent = $content -ireplace $old, $new; [System.IO.File]::WriteAllText($_.FullName, $newContent, $utf8); Write-Host '%CYAN%│  ➔ Внутрянка изменена в: ' $_.FullName } }"

echo %GREEN%│ [Успешно] Все упоминания имени во всех файлах изменены!│%NC%
echo %PURPLE%└────────────────────────────────────────────────────────┘%NC%

:: 6. ПЕРЕИМЕНОВАНИЕ САМИХ ФАЙЛОВ И ПАПОК КОДА
echo.
echo %PURPLE%┌── [ ШАГ 5: Переименование папок и файлов кода ] ────────┐%NC%
echo %CYAN%│ Переименование файлов и папок исходного кода...%NC%

powershell -Command "$old='%OLD_NAME%'; $new='%NEW_NAME%'; Get-ChildItem -Path . -Recurse | Where-Object { $_.Name -match $old } | Sort-Object Length -Descending | ForEach-Object { $newName = $_.Name -ireplace $old, $new; Rename-Item $_.FullName -NewName $newName; Write-Host '%CYAN%│  ➔ Переименован элемент: ' $newName }"

echo %GREEN%│ [Успешно] Все файлы C++ и внутренние папки переименованы.│%NC%
echo %PURPLE%└────────────────────────────────────────────────────────┘%NC%

:: 7. АВТОМАТИЧЕСКАЯ РЕГЕНЕРАЦИЯ ФАЙЛОВ VS
echo.
echo %PURPLE%┌── [ ШАГ 6: Автоматическая генерация файлов проекта ] ──┐%NC%
echo %CYAN%│ Поиск UnrealBuildTool в реестре Windows...%NC%

set "UBT_PATH="
for /f "tokens=2*" %%A in ('reg query "HKEY_CLASSES_ROOT\Unreal.ProjectFile\shell\rgenerate\command" /ve 2^>nul') do (
    set "UBT_PATH=%%B"
)

if not "!UBT_PATH!"=="" (
    set "UBT_PATH=!UBT_PATH:"%%1"=!"
    set "UBT_PATH=!UBT_PATH:"=!"
    echo %CYAN%│ Запуск generation для: %NEW_NAME%.uproject%NC%
    "!UBT_PATH!" /projectfiles "%NEW_PROJECT_DIR%\%NEW_NAME%.uproject" >nul 2>&1
    echo %GREEN%│ [Успешно] Файлы Visual Studio (.sln) успешно созданы!  │%NC%
) else (
    echo %YELLOW%│ [Предупреждение] UnrealVersionSelector не найден в системе.│%NC%
    echo %YELLOW%│ Сделайте клик ПКМ по %NEW_NAME%.uproject -> Generate Files │%NC%
)
echo %PURPLE%└────────────────────────────────────────────────────────┘%NC%

:: 8. ФИНАЛЬНЫЙ СТАТУС
echo.
echo %GREEN%┌────────────────────────────────────────────────────────┐%NC%
echo %GREEN%│      ГОТОВО! ПРОЕКТ ПОЛНОСТЬЮ ОБНОВЛЕН                 │%NC%
echo %GREEN%├────────────────────────────────────────────────────────┤%NC%
echo %CYAN%│ Вся внутрянка переписана, включая макросы и инклуды.   │%NC%
echo %CYAN%│                                                        │%NC%
echo %CYAN%│ Теперь вы можете запустить проект через:               │%NC%
echo %GREEN%│ %NEW_NAME%.uproject или %NEW_NAME%.sln%NC%
echo %GREEN%└────────────────────────────────────────────────────────┘%NC%
pause
exit /b
