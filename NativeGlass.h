#pragma once
#include <QImage>
#include <QRectF>
#include <QString>
#include <QWidget>

// Opaque native objects are owned by their Qt widget's view hierarchy.
void *addNativeGlass(QWidget *widget, qreal radius);
void removeNativeGlass(void *glass);
void syncNativeGlass(void *glass, QWidget *widget, const QRectF &bounds);
void setNativeGlassStyle(void *glass, bool clear, bool dark, bool solid);
bool nativeGlassIsValid(void *glass, QWidget *widget);
QImage applicationIcon(const QString &bundleId);
bool systemReducesMotion();
bool systemNeedsSolidSurfaces();
void configureNativeWindow(QWidget *widget);
