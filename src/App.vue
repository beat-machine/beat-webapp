<template>
  <div id="app">
    <Banner></Banner>

    <section class="upload">
      <h1>Upload</h1>
      <p>Choose an MP3 to upload.</p>
      <input type="file" v-on:change="updateFile" accept=".mp3" />
    </section>

    <section class="effects">
      <h1>Effects</h1>
      <p>Select up to 5 effects to add.</p>
      <div class="effect-box" v-for="(effect, i) in effects" v-bind:key="i">
        <div class="effect-header">EFFECT #{{ i + 1 }}</div>
        <EffectSelector v-bind:effects="effectDefinitions" ref="effect"></EffectSelector>
      </div>
      <div class="buttons">
        <input
          type="button"
          value="Add another"
          v-on:click="effects.push({})"
          :disabled="effects.length >= 5"
        />
        <input
          type="button"
          value="Remove last"
          v-on:click="effects.pop()"
          :disabled="effects.length <= 1"
        />
      </div>
    </section>

    <section class="submit">
      <h1>Result</h1>
      <p>Press submit to render the result. This tends to take about as long as the song.</p>
      <div class="progress-info" v-if="uploading || processing || error">
        <h2 v-if="uploading">Uploading...</h2>
        <template v-if="processing">
          <h2 class="color-cycle">Processing...</h2>
          <p>This will take a moment.</p>
        </template>
        <h2 v-if="error && !uploading && !processing">An error occurred: {{ error }}</h2>
      </div>
      <div class="player" v-if="audioUrl">
        <audio v-bind:src="audioUrl" controls type="audio/mpeg" autostart="0"></audio>
        <p>
          Right-click on the player above or
          <a :href="audioUrl" download>click here</a> to download.
        </p>
      </div>
      <div class="buttons">
        <span class="submit-hint">{{ submitMessage }}</span>
        <input value="Submit" type="button" v-on:click="submitSong()" :disabled="!canSubmit" />
      </div>
    </section>
    <p class="site-info">
      Check out the source for this page
      <a href="https://github.com/dhsavell/beat-webapp">here</a>.
    </p>
  </div>
</template>

<script>
import axios from "axios";
import Banner from "./components/Banner.vue";
import EffectSelector from "./components/EffectSelector.vue";
import effectDefinitions from "./assets/effects.json";

// const BASE_URI = "https://beatfunc-zz5hrgpina-uc.a.run.app";
const BASE_URI = "http://127.0.0.1:8000/";

export default {
  name: "app",
  data() {
    return {
      song: null,
      effects: [{}],
      effectDefinitions: effectDefinitions,
      pollToken: null,
      uploading: false,
      processing: false,
      error: null,
      audioUrl: null
    };
  },
  components: {
    Banner,
    EffectSelector
  },
  computed: {
    effectCount() {
      return this.$refs.effect.length;
    },
    serializedEffects() {
      return this.$refs.effect.map(e => e.serialized);
    },
    requestData() {
      let data = new FormData();

      data.append("song", this.song);
      data.append("effects", JSON.stringify(this.serializedEffects));

      return data;
    },
    canSubmit() {
      return this.song != null && !this.uploading && !this.processing;
    },
    submitMessage() {
      if (this.song == null) {
        return "No song selected.";
      } else if (this.uploading || this.processing) {
        return "Wait for the current song to finish rendering first.";
      } else {
        return "";
      }
    }
  },
  methods: {
    updateFile(e) {
      this.song = e.target.files[0];
    },
    async submitSong() {
      if (this.processing) {
        return;
      }

      this.resultError = null;
      this.submittedEffectCount = this.effectCount;

      try {
        this.uploading = true;

        let result = await axios.post(BASE_URI, this.requestData, {
          headers: {
            "Content-Type": "multipart/form-data"
          },
          responseType: "blob",
          onUploadProgress: function(event) {
            this.uploading = event.loaded < event.total;
            this.processing = !this.uploading;
          }.bind(this)
        });

        if (result.status >= 500) {
          this.error =
            "The server may be under heavy load. Try again in a few minutes.";
          this.audioUrl = null;
          return;
        }

        let blob = new Blob([result.data], { type: "audio/mpeg" });
        this.audioUrl = URL.createObjectURL(blob);
      } catch (e) {
        this.error = e;
        this.audioUrl = null;
      } finally {
        this.uploading = false;
        this.processing = false;
      }
    }
  }
};
</script>

<style lang="scss">
@import url("https://fonts.googleapis.com/css?family=Karla|Space+Mono&display=swap");

$background: #111;
$disabled-text: #888;
$text: #aaa;
$primary-text: #eee;

$accent-1: #faeb2c;
$accent-2: #f52789;
$accent-3: #e900ff;
$accent-4: #1685f8;

@keyframes colors {
  0% {
    color: $accent-1;
  }

  25% {
    color: $accent-2;
  }

  50% {
    color: $accent-3;
  }

  75% {
    color: $accent-4;
  }
}

body {
  background-color: $background;
  font-family: "Karla", sans-serif;
  color: $text;
}

h1 {
  font-family: "Space Mono", monospace;
  color: $primary-text;
}

select,
input[type="number"] {
  font-family: "Space Mono", monospace;
  font-weight: bold;
  background-color: inherit;
  color: $primary-text;
  padding: 8px;
  border: 2px solid $text;
}

input[type="button"] {
  font-family: "Space Mono", monospace;
  font-weight: bold;
  background-color: $text;
  border: none;
  padding: 8px;
  margin-left: 8px;
  color: $background;
}

a {
  color: $primary-text;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

input[type="button"]:disabled {
  color: $disabled-text;
  background-color: $background;
  text-decoration: line-through;
}

#app {
  padding-top: 40px;
  width: 80%;

  @media (min-width: 1400px) {
    width: 60%;
  }

  margin-left: auto;
  margin-right: auto;
}

.effect-box {
  border: 2px solid $text;
  margin-bottom: 16px;
}

section {
  border: 2px solid $text;
  padding: 20px;
  margin-bottom: 48px;
  background-color: $background;
  box-shadow: 8px 16px 0px 0px $text;
}

section h1 {
  margin-top: 0;
  margin-bottom: 2px;
}

.buttons {
  text-align: right;
}

.effect-header {
  background-color: $text;
  color: $background;
  font-family: "Space Mono", monospace;
  padding: 4px;
}

audio {
  display: block;
  width: 100%;
}

.progress-info {
  text-align: center;
  margin-top: 32px;
  margin-bottom: 32px;
  line-height: 80%;
}

.color-cycle {
  animation: colors 4s infinite steps(1, end);
  transition: none;
}

.submit-hint {
  margin-right: 16px;
  display: inline-block;
  margin-top: 0;
  margin-left: 16px;
  margin-bottom: 0px;
}
</style>

