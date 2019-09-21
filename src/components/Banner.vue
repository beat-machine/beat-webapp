<template>
  <div class="banner">
    <h1 class="title">The</h1>
    <h1 class="title">Beat</h1>
    <h1 class="title">Machine</h1>
    <h2 class="subtitle" v-on:click="chooseTagline()">{{ tagline }}</h2>
    <p class="site-description">
      The Beat Machine is a webapp for creating beat-based edits of songs (i.e.
      X but every other beat is missing) from the comfort of your browser. It's
      also available as a
      <a href="https://pypi.org/project/beatmachine/">Python library</a>, which
      runs a lot faster and lets you create your own effects.
    </p>
  </div>
</template>

<script>
import taglines from "../assets/taglines.json";

export default {
  data() {
    return {
      taglines: taglines,
      tagline: ""
    };
  },
  methods: {
    chooseTagline() {
      this.tagline = this.taglines[
        Math.floor(Math.random() * this.taglines.length)
      ];
    }
  },
  created() {
    this.chooseTagline();
  }
};
</script>

<style lang="scss">
.banner {
  font-size: 12pt;

  @media (min-width: 1400px) {
    width: 100%;
    font-size: 24pt;
  }

  margin-left: auto;
  margin-right: auto;
  font-size: 24pt;
  margin-bottom: 40px;
  line-height: 55px;
}

.site-description {
  font-size: 16pt;
  line-height: 32px;
}

.title {
  margin-bottom: 0;
  line-height: 20px;
}

.subtitle {
  margin-top: 32px;
  font-size: 20pt;
  line-height: 35px;
  user-select: none;
}
</style>
