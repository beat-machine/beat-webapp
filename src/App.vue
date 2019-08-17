<template>
  <div id="app">
    <Banner></Banner>

    <section class="upload">
      <h1>Upload</h1>
      <p>Choose and configure a song.</p>
      <descriptive-input
        fieldId="suggested-bpm"
        label="MP3 File"
        help="Shorter songs process faster!"
      >
        <input type="file" v-on:change="updateFile" accept=".mp3" />
      </descriptive-input>
      <collapsible-box header="Optional Beat Detection Settings" startCollapsed>
        <descriptive-input
          fieldId="use-custom-bpm"
          label="Custom Tempo"
          help="Check this to tell the AI what tempo to use."
          inlineField
        >
          <styled-checkbox v-model="useCustomBpm" id="use-custom-bpm" type="checkbox" />
        </descriptive-input>

        <descriptive-input
          fieldId="suggested-bpm"
          label="BPM Estimate"
          help="Average song BPM. Set this if results are twice as fast or slow."
          :disabled="!useCustomBpm"
        >
          <input
            v-model.number="suggestedBpm"
            id="suggested-bpm"
            type="number"
            min="30"
            max="300"
            :disabled="!useCustomBpm"
          />
        </descriptive-input>

        <descriptive-input
          fieldId="suggested-bpm"
          label="BPM Drift"
          help="Max deviation from the given BPM."
          :disabled="!useCustomBpm"
        >
          <input
            v-model.number="drift"
            id="max-drift"
            type="number"
            min="5"
            max="25"
            :disabled="!useCustomBpm"
          />
        </descriptive-input>
      </collapsible-box>
    </section>

    <section class="effects">
      <h1>Effects</h1>
      <p>Select up to 5 effects to add.</p>
      <collapsible-box v-for="(effect, i) in effects" v-bind:key="i" :header="'Effect #' + (i + 1)">
        <effect-selector v-bind:effects="effectDefinitions" ref="effect"></effect-selector>
      </collapsible-box>
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
      <p>Press submit to render the result. This will probably take a while.</p>
      <div class="progress-info" v-if="uploading || processing || error">
        <h2 v-if="uploading">Uploading...</h2>
        <template v-if="processing">
          <h2 class="color-cycle">Processing...</h2>
          <p>This will take a moment.</p>
        </template>
        <template v-if="error && !uploading && !processing">
          <h2>An error occurred ({{ error }}).</h2>
          <p>Frequent network issues are being investigated. In the meantime, try again in a minute. The server might be under heavy load.</p>
        </template>
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

    <div class="site-info">
      <p>
        Last update: {{ commitInfo }} ({{ commitHash }})
        on {{ commitTimestamp.getFullYear() }}-{{ ('0' + commitTimestamp.getMonth()).slice(-2) }}-{{ ('0' + commitTimestamp.getDate()).slice(-2) }}
      </p>
      <p>
        Created by
        <a href="https://twitter.com/branchpanic">@branchpanic</a>.
        Check out the source for this page
        <a
          href="https://github.com/dhsavell/beat-webapp"
        >here</a>.
      </p>
    </div>
  </div>
</template>

<script>
import axios from "axios";
import Banner from "./components/Banner.vue";
import EffectSelector from "./components/EffectSelector.vue";
import DescriptiveInput from "./components/DescriptiveInput.vue";
import CollapsibleBox from "./components/CollapsibleBox.vue";
import StyledCheckbox from "./components/StyledCheckbox.vue";
import effectDefinitions from "./assets/effects.json";

const BASE_URL = "http://localhost:8000";

export default {
  name: "app",
  data() {
    return {
      // Configuration
      effectDefinitions: effectDefinitions,

      // State management
      song: null,
      effects: [{}],
      uploading: false,
      processing: false,
      error: null,
      audioUrl: null,

      // Advanced settings
      useCustomBpm: false,
      suggestedBpm: 100,
      drift: 15,

      // Webpack injected constants (all remaining properties)

      // eslint-disable-next-line
      commitInfo: COMMIT_INFO,

      // eslint-disable-next-line
      commitHash: COMMIT_HASH,

      // eslint-disable-next-line
      commitTimestamp: new Date(parseInt(COMMIT_TIMESTAMP) * 1000)
    };
  },
  components: {
    Banner,
    EffectSelector,
    DescriptiveInput,
    CollapsibleBox,
    StyledCheckbox
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

      let effectPayload = {
        settings: {},
        effects: this.serializedEffects
      };

      if (this.useCustomBpm) {
        effectPayload.settings = {
          suggested_bpm: this.suggestedBpm,
          drift: this.drift
        };
      }

      data.append("effects", JSON.stringify(effectPayload));

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
    invalidSwapEffectExists() {
      for (let e of this.$refs.effect) {
        let params = e.currentParams;
        if (
          "x_period" in params &&
          "y_period" in params &&
          params["x_period"] === params["y_period"]
        ) {
          return true;
        }
      }

      return false;
    },
    async submitSong() {
      if (this.processing) {
        return;
      }

      if (this.invalidSwapEffectExists()) {
        this.error =
          "Can't swap a beat with itself. Double-check any swap effects.";
        return;
      }

      try {
        this.uploading = true;

        let result = await axios.post(BASE_URL, this.requestData, {
          headers: {
            "Content-Type": "multipart/form-data"
          },
          responseType: "blob",
          timeout: 480 * 1000,
          onUploadProgress: function(event) {
            this.uploading = event.loaded < event.total;
            this.processing = !this.uploading;
          }.bind(this)
        });

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
@import "./scss/global.scss";

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

.container {
  padding: 16px;
}

h1 {
  font-family: "Space Mono", monospace;
  color: $primary-text;
}

input[type="button"] {
  font-family: "Space Mono", monospace;
  font-weight: bold;
  border: none;
  padding: 8px;
  margin-left: 16px;
  background-color: $text;
  color: $background;
  transition: background-color 0.1s $fast-ease;
}

input[type="button"]:hover {
  background-color: $accent-1;
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
  padding-bottom: 40px;
  width: 80%;

  @media (min-width: 1400px) {
    width: 60%;
  }

  margin-left: auto;
  margin-right: auto;
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

audio {
  display: block;
  width: 100%;
}

.progress-info {
  text-align: center;
  margin-top: 32px;
  margin-bottom: 32px;
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
