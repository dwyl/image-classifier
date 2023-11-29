// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

// Hooks to track inactivity
let Hooks = {};
Hooks.ActivityTracker = {
  mounted() {
    // Set the inactivity duration in milliseconds
    const inactivityDuration = 8000; // 8 seconds

    // Set a variable to keep track of the timer and if the process to predict example image has already been sent
    let inactivityTimer;
    let processHasBeenSent = false;

    // We use the `mounted()` context to push the event. This is used in the `setTimeout` function below.
    let ctx = this

    // Function to reset the timer
    function resetInactivityTimer() {
      // Clear the previous timer
      clearTimeout(inactivityTimer);

      // Start a new timer
      inactivityTimer = setTimeout(() => {
        // Perform the desired action after the inactivity duration
        // For example, send a message to the Elixir process using Phoenix Socket
        if (!processHasBeenSent) {
          processHasBeenSent = true;
          ctx.pushEvent("show_examples", {});
        }
      }, inactivityDuration);
    }

    // Call the function to start the timer initially
    resetInactivityTimer();

    // Reset the timer whenever there is user activity
    document.addEventListener("mousemove", resetInactivityTimer);
    document.addEventListener("keydown", resetInactivityTimer);
  },
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken } });

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
