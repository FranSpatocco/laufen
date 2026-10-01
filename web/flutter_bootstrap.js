{{flutter_js}}
{{flutter_build_config}}

// Custom bootstrap (instead of Flutter's generated default) only to fade
// out the HTML loading splash from index.html once the app is running.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const splash = document.getElementById('splash');
    if (splash) {
      // Give Flutter a beat to paint its first frame under the splash.
      setTimeout(() => {
        splash.style.opacity = '0';
        setTimeout(() => splash.remove(), 400);
      }, 300);
    }
  },
});
