<template>
  <div class="effect-selector">
    <select v-model="selectedEffectIndex" v-on:change="updateParams()">
      <option v-for="(effect, i) in effects" v-bind:key="i" :value="i">{{ effect.name }}</option>
    </select>
    <p>{{ selectedEffect.description }}</p>
    <template v-for="(param, i) in selectedEffect.params">
      <span v-bind:key="i">
        <label>{{ param.name }}</label>
        <input type="number" v-model.number="currentParams[param.id]" v-bind:min="param.minimum">
      </span>
    </template>
  </div>
</template>

<script>
export default {
  props: {
    effects: Array
  },
  data() {
    return {
      selectedEffectIndex: 0,
      currentParams: {}
    };
  },
  computed: {
    selectedEffect() {
      return this.effects[this.selectedEffectIndex];
    },
    serialized() {
      return { type: this.selectedEffect.id, ...this.currentParams };
    }
  },
  methods: {
    updateParams() {
      this.currentParams = {};
      for (let x of this.selectedEffect.params) {
        this.currentParams[x.id] = x.value;
      }
    }
  },
  created: function() {
    this.updateParams();
  }
};
</script>

<style>
</style>
