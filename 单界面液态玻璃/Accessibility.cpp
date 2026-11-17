#include <QGuiApplication>
#include <QAccessibilityHints>
#include <QStyleHints>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

bool reducesMotion()
{
#ifdef Q_OS_WIN
    BOOL animated = TRUE;
    return SystemParametersInfoW(SPI_GETCLIENTAREAANIMATION, 0, &animated, 0) && !animated;
#else
    return false;
#endif
}

bool needsSolidSurface()
{
#ifdef Q_OS_WIN
    HIGHCONTRASTW contrast{};
    contrast.cbSize = sizeof(contrast);
    if (SystemParametersInfoW(SPI_GETHIGHCONTRAST, sizeof(contrast), &contrast, 0)
        && (contrast.dwFlags & HCF_HIGHCONTRASTON)) return true;
    DWORD transparency = 1;
    DWORD size = sizeof(transparency);
    return RegGetValueW(HKEY_CURRENT_USER,
        L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
        L"EnableTransparency", RRF_RT_REG_DWORD, nullptr, &transparency, &size) == ERROR_SUCCESS
        && transparency == 0;
#else
    return QGuiApplication::styleHints()->accessibility()->contrastPreference() == Qt::ContrastPreference::HighContrast;
#endif
}
