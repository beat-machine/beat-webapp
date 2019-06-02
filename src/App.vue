<template>
  <div id="app">
    <Banner></Banner>
    <section class="section">
      <div class="container">
        <div class="columns">
          <div class="column">
            <h1 class="title">Upload</h1>
            <p
              class="content"
            >Upload a song, specify its BPM, choose effects, and then press the submit button to start processing. For best results, choose a song with no buildup or leading silence.</p>
            <b-field label="Song">
              <b-field class="file">
                <b-upload v-model="song" accept="audio/mpeg">
                  <a class="button is-primary">
                    <b-icon icon="upload"></b-icon>
                    <span>Select an MP3</span>
                  </a>
                </b-upload>
                <span class="file-name" v-if="song">{{ song.name }}</span>
              </b-field>
            </b-field>
            <b-field label="BPM" message="This can often be found online.">
              <b-numberinput controls-position="compact" v-model.number="bpm"></b-numberinput>
            </b-field>
            <b-field>
              <b-button
                v-on:click="submitSong()"
                type="is-success"
                v-if="!processing && !uploading"
              >Submit</b-button>
              <b-button v-else type="is-loading is-success" disabled>Submit</b-button>
            </b-field>
            <h1 class="title">Result</h1>
            <b-notification
              type="is-danger"
              v-bind:closable="false"
              role="alert"
              v-if="resultError"
            >{{ resultError }}</b-notification>
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
            <audio v-bind:src="resultUri" v-if="resultUri" controls type="audio/mpeg" autostart="0"></audio>
            <p v-else>The latest result will appear here.</p>
          </div>
          <div class="column">
            <h1 class="title">Effects</h1>
            <p
              class="content"
            >Select effects to add to the song. Period refers to how often the effect is applied (i.e. a period of 1 means every single beat while a period of 2 means every other one).</p>
            <div class="box" v-for="(effect, i) in effects" v-bind:key="i">
              <EffectSelector v-bind:effects="effectDefinitions" ref="effect"></EffectSelector>
            </div>
            <div class="buttons">
              <b-button type="is-light is-fullwidth is-medium" v-on:click="effects.push({})">
                <b-icon icon="plus"></b-icon>
              </b-button>
              <b-button
                type="is-light is-fullwidth is-medium"
                v-if="effects.length > 1"
                v-on:click="effects.pop()"
              >
                <b-icon icon="minus"></b-icon>
              </b-button>
            </div>
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

const BASE_URI = "https://beat-api.herokuapp.com";

export default {
  name: "app",
  data() {
    return {
      song: null,
      bpm: 100,
      effects: [{}],
      effectDefinitions: effectDefinitions,
      pollToken: null,
      uploading: false,
      uploadPercentage: 0,
      processing: false,
      resultUri: null,
      resultError: null,
      progress: 0,
      submittedEffectCount: 0
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
      data.append(
        "data",
        JSON.stringify({
          bpm: this.bpm,
          effects: this.serializedEffects
        })
      );

      return data;
    },
    isProcessing() {
      return this.pollToken !== null;
    }
  },
  methods: {
    async submitSong() {
      if (this.processing) {
        return;
      }

      this.resultError = null;
      this.submittedEffectCount = this.effectCount;

      try {
        this.uploading = true;

        let response = await axios.post(
          BASE_URI + "/api/v0/submit",
          this.requestData,
          {
            headers: {
              "Content-Type": "multipart/form-data"
            },
            onUploadProgress: function(event) {
              this.uploadPercentage = parseInt(
                Math.round((event.loaded * 100) / event.total)
              );
            }.bind(this)
          }
        );

        this.startPolling(response.data.status.href);
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
