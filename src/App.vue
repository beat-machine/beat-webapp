<template>
  <div id="app">
    <Banner></Banner>
    <section class="section">
      <div class="container">
        <div class="columns">
          <div class="column">
            <h1 class="title">Effects</h1>
            <p
              class="content"
            >Select effects to add to the song. Period refers to how often the effect is applied (i.e. a period of 1 means every single beat while a period of 2 means every other one).</p>
            <div class="box" v-for="(effect, i) in effects" v-bind:key="i">
              <EffectSelector v-bind:effects="effectDefinitions" ref="effect"></EffectSelector>
            </div>
            <div class="buttons">
              <button type="is-light is-fullwidth is-medium" v-on:click="effects.push({})">add</button>
              <button
                type="is-light is-fullwidth is-medium"
                v-if="effects.length > 1"
                v-on:click="effects.pop()"
              >remove</button>
            </div>
          </div>
          <div class="column">
            <h1 class="title">Upload</h1>
            <input type="file" v-on:change="updateFile" accept=".mp3" />
            <span class="file-name" v-if="song">{{ song.name }}</span>
            <button
              v-on:click="submitSong()"
              type="is-success"
              v-if="!processing && !uploading"
            >Submit</button>
            <button v-else type="is-loading is-success" disabled>Submit</button>
            <template v-if="uploading">
              <small>Uploading audio</small>
              <progress class="progress is-dark" v-bind:max="100" v-bind:value="uploadPercentage"></progress>
            </template>
            <template v-if="processing">
              <small>Processing effect {{ progress }} of {{ submittedEffectCount }}</small>
              <progress
                class="progress is-primary"
                v-bind:value="progress"
                v-bind:max="submittedEffectCount"
              ></progress>
            </template>
            <audio v-bind:src="audioUrl" v-if="audioUrl" controls type="audio/mpeg" autostart="0"></audio>
            <p v-else>Submit a song to see the result!</p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script>
import axios from "axios";
import Banner from "./components/Banner.vue";
import EffectSelector from "./components/EffectSelector.vue";
import { setInterval, clearInterval } from "timers";
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
      uploadPercentage: 0,
      processing: false,
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
    isProcessing() {
      return this.pollToken !== null;
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

        axios
          .post(BASE_URI, this.requestData, {
            headers: {
              "Content-Type": "multipart/form-data"
            },
            responseType: "blob",
            onUploadProgress: function(event) {
              this.uploadPercentage = parseInt(
                Math.round((event.loaded * 100) / event.total)
              );
            }.bind(this)
          })
          .then(r => {
            let blob = new Blob([r.data], { type: "audio/mpeg" });
            this.audioUrl = URL.createObjectURL(blob);
          });
      } catch (e) {
        this.resultError = e;
        this.$toast.open("An error occurred.");
      } finally {
        this.uploading = false;
      }
    },
    startPolling(statusUri) {
      if (this.pollToken != null) {
        clearInterval(this.pollToken);
      }

      this.processing = true;
      this.pollToken = setInterval(() => this.poll(statusUri), 3000);
    },
    async poll(statusUri) {
      let baseUri = BASE_URI + statusUri;
      let result = await axios.get(baseUri);

      if (result.data.state === "SUCCESS") {
        this.resultUri = BASE_URI + result.data.location;
        this.processing = false;
        this.$toast.open("Finished!");
        clearInterval(this.pollToken);
      } else if (result.data.state === "PROGRESS") {
        this.progress = result.data.current_effect;
      } else {
        this.error = "An error occurred.";
        this.processing = false;
        clearInterval(this.pollToken);
      }
    }
  }
};
</script>

<style>
</style>
