<template>
  <section class="hero is-info">
    <div class="hero-body">
      <div class="container">
        <h1 class="title">The Beat Machine</h1>
        <h2 class="subtitle" v-on:click="chooseTagline()">{{ tagline }}</h2>
      </div>
    </div>
  </section>
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
