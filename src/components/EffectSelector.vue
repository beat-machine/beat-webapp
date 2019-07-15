<template>
  <div class="effect-selector">
    <select v-model="selectedEffectIndex" v-on:change="updateParams()">
      <option v-for="(effect, i) in effects" v-bind:key="i" v-bind:value="i">{{ effect.name }}</option>
    </select>
    <small>{{ selectedEffect.description }}</small>
    <div class="container">
      <div v-for="(param, i) in selectedEffect.params" v-bind:label="param.name" v-bind:key="i">
        <input type="number" v-model.number="currentParams[param.id]" v-bind:min="param.minimum" />
      </div>
    </div>
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
        this.currentParams[x.id] = x.default;
      }
    }
  },
  watch: {
    selectedEffectIndex() {
      this.updateParams();
    }
  },
  created() {
    this.updateParams();
  }
};
</script>

<style>
</style>
