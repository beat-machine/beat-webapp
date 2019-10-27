<template>
  <div id="app">
    <banner></banner>

    <section>
      <h1>Song</h1>
      <p>Choose and configure a song. Shorter songs process faster!</p>
      <descriptive-input fieldId="suggested-bpm" label="MP3 File">
        <styled-upload v-model="song" accept=".mp3, audio/mpeg" />
      </descriptive-input>
      <collapsible-box header="Optional Settings" startCollapsed>
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
          fieldId="max-drift"
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

    <section>
      <h1>Effects</h1>
      <p>Select up to 5 effects to add.</p>
      <collapsible-box v-for="(effect, i) in effects" :key="i" :header="'Effect #' + (i + 1)" :class="{ error: !effect.valid }">
        <effect-selector :effects="effectDefinitions" v-model="effects[i]"></effect-selector>
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

    <section>
      <h1>Result</h1>
      <p>Press submit to render the result.</p>
      <div class="progress-info" v-if="uploading || processing || error">
        <h2 v-if="uploading">Uploading...</h2>
        <template v-if="processing">
          <h2 class="color-cycle">Processing...</h2>
          <p>This will take a moment.</p>
        </template>
        <template v-if="error && !uploading && !processing">
          <h2>An error occurred ({{ error }}).</h2>
          <p>Try again in a moment. The server might be under heavy load.</p>
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

    <section class="subtle">
      <h1>Support</h1>
      <p>
        If you enjoy The Beat Machine and would like to fund future development
        (better servers -> less timeouts), please consider supporting me on
        Patreon! One-time tips are welcome.
      </p>
      <p>
        Patrons get comprehensive status posts, polls concerning new
        features, and optionally social links displayed at the bottom of this
        site.
      </p>
      <div class="buttons">
        <a
          href="https://www.patreon.com/branchpanic"
          class="button"
          target="_blank"
        >Donate on Patreon</a>
      </div>
    </section>

    <div class="site-info">
      <p>
        Last commit: {{ commitInfo }} ({{ commitHash }}) on
        {{ commitTimestamp.getFullYear() }}-{{
        ("0" + commitTimestamp.getMonth()).slice(-2)
        }}-{{ ("0" + commitTimestamp.getDate()).slice(-2) }}
      </p>
      <p>
        Version {{ version }}.
        Created by
        <a href="https://twitter.com/branchpanic">@branchpanic</a>. Check out
        the source for this page
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
import StyledUpload from "./components/StyledUpload.vue";

import { effectDefinitions } from "@/js/effects";

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
      commitTimestamp: new Date(parseInt(COMMIT_TIMESTAMP) * 1000),

      version: process.env.BEATAPP_VERSION,
    };
  },
  components: {
    Banner,
    EffectSelector,
    DescriptiveInput,
    CollapsibleBox,
    StyledCheckbox,
    StyledUpload
  },
  computed: {
    effectCount() {
      return this.effects.length;
    },
    serializedEffects() {
      return this.effects.map(e => e.serialized);
    },
    invalidEffectsExist() {
      return this.effects.some(e => !e.valid);
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
      return this.song != null && !this.uploading && !this.processing && !this.invalidEffectsExist;
    },
    submitMessage() {
      if (this.song == null) {
        return "No song selected.";
      } else if (this.uploading || this.processing) {
        return "Wait for the current song to finish rendering first.";
      } else if (this.invalidEffectsExist) {
        return "One or more effects have problems."
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

      try {
        this.uploading = true;
        let result = await axios.post(
          process.env.BEATAPP_BASE_URL /* replaced by Webpack */,
          this.requestData,
          {
            headers: {
              "Content-Type": "multipart/form-data"
            },
            responseType: "blob",
            timeout: 480 * 1000,
            onUploadProgress: function(event) {
              this.uploading = event.loaded < event.total;
              this.processing = !this.uploading;
            }.bind(this)
          }
        );

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
@import "@/scss/global.scss";

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

a {
  color: $primary-text;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

section {
  border: 2px solid $frames;
  padding: 20px;
  margin-bottom: 48px;
  background-color: $background;
  box-shadow: 8px 16px 0px 0px $frames;
}

section.subtle {
  border: none;
  box-shadow: none;
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

body {
  background-color: $background;
  font-family: "Karla", sans-serif;
  color: $text;
}

h1 {
  font-family: "Space Mono", monospace;
  color: $primary-text;
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

a.button {
  display: inline-block;
}

a.button:hover {
  text-decoration: none;
}

input[type="button"],
.button {
  font-family: "Space Mono", monospace;
  font-weight: bold;
  border: none;
  padding: 8px;
  background-color: $text;
  color: $background;
  transition: background-color 0.12s $fast-ease;
}

input[type="button"]:hover,
.button:hover {
  background-color: $accent-1;
}

input[type="button"]:disabled {
  color: $disabled-text;
  background-color: $background;
  text-decoration: line-through;
}

.buttons input[type="button"] {
  margin-left: 16px;
}

a {
  color: $accent-4;
}
</style>
