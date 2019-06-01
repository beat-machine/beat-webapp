<template>
  <div id="app">
    <div class="upload">
      <input type="file" accept="audio/mpeg" v-on:change="updateSelectedSong($event)">
      <input type="number" v-model.number="bpm">
      <button v-on:click="submitSong()">submit</button>
    </div>
    <div class="effects">
      <EffectSelector
        v-for="(effect, i) in effects"
        v-bind:key="i"
        v-bind:effects="effectDefinitions"
        ref="effect"
      ></EffectSelector>
    </div>
    <div class="status">
      <div>{{status}}</div>
      <a :href="lastResultUri">Result</a>
    </div>
  </div>
</template>

<script>
import axios from "axios";
import EffectSelector from "./components/EffectSelector.vue";
import { setInterval, clearInterval } from "timers";
import effectDefinitions from "./assets/effects.json";

const BASE_URI = "http://beat-api.herokuapp.com";

export default {
  name: "app",
  data() {
    return {
      song: null,
      bpm: 100,
      effects: [{}],
      effectDefinitions: effectDefinitions,
      status: "not processing",
      pollToken: null,
      lastResultUri: "#"
    };
  },
  components: {
    EffectSelector
  },
  computed: {
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
    }
  },
  methods: {
    updateSelectedSong(e) {
      this.song = e.target.files[0];
    },
    async submitSong() {
      try {
        let response = await axios.post(
          BASE_URI + "/api/v0/submit",
          this.requestData,
          {
            headers: {
              "Content-Type": "multipart/form-data"
            }
          }
        );
        this.startPolling(response.data.status.href);
      } catch (e) {
        console.warn("that's a shame", e);
      }
    },
    startPolling(statusUri) {
      if (this.pollToken != null) {
        clearInterval(this.pollToken);
      }

      this.pollToken = setInterval(
        async function() {
          let baseUri = BASE_URI + statusUri;
          let result = await axios.get(baseUri, { maxRedirects: 0 });

          if (result.data.state === "SUCCESS") {
            this.lastResultUri = BASE_URI + result.data.location;
            clearInterval(this.pollToken);
          } else {
            console.log(result.data.state);
          }
        }.bind(this),
        3000
      );
    }
  }
};
</script>

<style>
</style>
