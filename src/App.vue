<template>
  <div id="app">
    <EffectSelector
      v-for="(effect, i) in effects"
      v-bind:key="i"
      v-bind:effects="allEffects()"
      ref="effect"
    ></EffectSelector>
  </div>
</template>

<script>
import EffectSelector from "./components/EffectSelector.vue";

export default {
  name: "app",
  data() {
    return {
      effects: [{}, {}]
    };
  },
  components: {
    EffectSelector
  },
  computed: {
    serializedEffects() {
      return this.$refs.effect.map(e => e.serialized);
    }
  },
  methods: {
    allEffects() {
      return [
        {
          id: "swap",
          name: "Swap",
          description: "Swaps two beats throughout the entire song.",
          params: [
            {
              id: "x_period",
              name: "Every",
              value: 2,
              minimum: 1
            },
            {
              id: "y_period",
              name: "With",
              value: 4,
              minimum: 1
            }
          ]
        },
        {
          id: "randomize",
          name: "Randomize",
          description: "Totally randomizes all beats. It's pretty terrible.",
          params: []
        }
      ];
    }
  }
};
</script>

<style>
</style>
