import toWav from "audiobuffer-to-wav";

export default {
  mounted() {
    let mediaRecorder,
      audioChunks = [];

    // Defining the elements and styles to be used during recording
    // and shown on the HTML.
    const recordButton = document.getElementById("record"),
      audioElement = document.getElementById("audio"),
      text = document.getElementById("text"),
      blue = ["bg-blue-500", "hover:bg-blue-700"],
      pulseGreen = ["bg-green-500", "hover:bg-green-700", "animate-pulse"];

    _this = this;

    // Adding event listener for "click" event
    recordButton.addEventListener("click", () => {
      // Check if it's recording.
      // If it is, we stop the record and update the elements.
      if (mediaRecorder && mediaRecorder.state === "recording") {
        mediaRecorder.stop();
        // audioChunks.getAudioTracks()[0].stop();
        text.textContent = "Record";
      }

      // Otherwise, it means the user wants to start recording.
      else {
        navigator.mediaDevices.getUserMedia({ audio: true }).then((stream) => {
          // Instantiate MediaRecorder
          mediaRecorder = new MediaRecorder(stream);
          mediaRecorder.start()

          // And update the elements
          recordButton.classList.remove(...blue);
          recordButton.classList.add(...pulseGreen);
          text.textContent = "Stop";

          // Add "dataavailable" event handler
          mediaRecorder.addEventListener("dataavailable", (event) => {
            event.data.size > 0 && audioChunks.push(event.data);
          });

          // Add "stop" event handler for when the recording stops.
          mediaRecorder.addEventListener("stop", async () => {
            const audioBlob = new Blob(audioChunks);

            // update the source of the Audio tag for the user to listen to his audio
            audioElement.src = URL.createObjectURL(audioBlob);

            // create an AudioContext with a sampleRate of 16000
            const audioContext = new AudioContext({ sampleRate: 16000 });

            // We optimize the audio to reduce the size of the file whilst maintaining the necessary information for the model -----------
            // async read the Blob as ArrayBuffer to feed the "decodeAudioData"
            const arrayBuffer = await audioBlob.arrayBuffer();
            // decodes the ArrayBuffer into the AudioContext format
            const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
            // converts the AudioBuffer into a WAV format
            const wavBuffer = toWav(audioBuffer);
            // builds a Blob to pass to the Phoenix.JS.upload
            const wavBlob = new Blob([wavBuffer], { type: "audio/wav" });

            
            // upload to the server via a chanel with the built-in Phoenix.JS.upload
            _this.upload("speech", [wavBlob]);
            //  close the MediaRecorder instance
            mediaRecorder.stop();
            
            // cleanups
            audioChunks = [];
            recordButton.classList.remove(...pulseGreen);
            recordButton.classList.add(...blue);
          });
        });
      }
    });
  },
};

