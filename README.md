# NewtonCoach ⚡️🏋️‍♂️

> Tu entrenador personal, preparador físico y estratega nutricional impulsado por la IA de **Newton Labs Gateway**, diseñado en **Swift & SwiftUI** para iOS con enfoque **100% Local-First** y compilación automatizada en **GitHub Actions**.

---

## ✨ Features Principales

- 👤 **Perfil y Metas de Peso Precisas**:
  - Ingreso de peso actual, peso deseado y plazo objetivo (días / semanas).
  - Cálculo de edad a partir de tu **Fecha de Cumpleaños**.
  - Notificación y medalla conmemorativa el día de tu cumpleaños.
- 🥗 **Menú Diario Inteligente con Newton AI**:
  - Generación de comidas personalizadas (Desayuno, Almuerzo, Merienda, Cena) ajustadas a tus calorías y macronutrientes calculados con **Mifflin-St Jeor**.
  - **MacroLens Vision**: Escanea cualquier plato con la cámara de tu iPhone para que Newton Vision estime calorías y macros al instante.
- 💬 **Coach Deportivo en Streaming SSE**:
  - Chat interactivo token a token (`POST /nwtn/chat?stream=true`) con rigor científico.
  - Contextualizado con tus datos corporales, calorías diarias y progreso.
- 🔔 **Notificaciones & Recordatorios Locales**:
  - Recordatorios automáticos en el dispositivo para pesaje en ayunas (07:30 AM), almuerzo (13:30 PM), entreno (18:00 PM) e hidratación.
- 🏆 **Sistema de Logros & Medallas (Achievements)**:
  - Desbloqueo de insignias por constancia, cumplimiento de metas de peso y registro de comidas.
- 🔒 **100% Local & Privacidad Total**:
  - Cero almacenamiento en la nube externa. Tus datos y peso permanecen en tu iPhone.
  - Tu API Key de Newton (`ntwn-...`) se guarda cifrada en el **iOS Keychain**.

---

## 🛠️ Arquitectura Técnica

- **Lenguaje**: Swift 5.9+ / SwiftUI
- **Target OS**: iOS 16.0+ (iPhone & iPad)
- **Compilación CI/CD**: GitHub Actions en `macos-15` con la versión más reciente de Xcode (`xcode-latest`).
- **Gestor de Proyecto**: [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) para proyectos de Xcode limpios y sin conflictos de merge.

---

## 🚀 Compilación en GitHub Actions

Este repositorio está preparado para compilarse automáticamente sin necesidad de compilar en tu máquina local:

1. Haz push de tus cambios a la rama `main` de tu repositorio en GitHub:
   ```bash
   git add .
   git commit -m "feat: initial commit for NewtonCoach"
   git push origin main
   ```
2. Ve a la pestaña **Actions** en tu repositorio de GitHub.
3. El workflow `Build & Release iOS App` se ejecutará en un runner `macos-15` con el último Xcode disponible.
4. Al finalizar la compilación, descarga el archivo en **Artifacts** (`NewtonCoach-iOS-Release`), que contiene el paquete `.ipa` y `.zip` listo para instalar mediante AltStore, TrollStore, TestFlight o instalación ad-hoc.

---

## 🔑 Configuración de Newton Labs API

1. Abre la aplicación NewtonCoach en tu iPhone.
2. Dirígete a la pestaña **Ajustes** (`gearshape.fill`).
3. En la sección *Newton Labs API Gateway*, introduce tu API Key (`ntwn-...`).
4. Pulsa **Guardar API Key**. Se almacenará en el Keychain seguro del dispositivo.

---

## 📄 Licencia

Este proyecto es Open Source bajo la licencia [MIT](LICENSE).
