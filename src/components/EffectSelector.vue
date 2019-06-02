<template>
  <div class="effect-selector">
    <b-field>
      <b-dropdown v-model="selectedEffectIndex" v-on:change="updateParams()">
        <b-button type="is-medium is-primary" slot="trigger">
          <span>{{ selectedEffect.name }}</span>
          <b-icon icon="menu-down"></b-icon>
        </b-button>
        <b-dropdown-item v-for="(effect, i) in effects" v-bind:key="i" v-bind:value="i">
          <h2>{{ effect.name }}</h2>
          <small>{{ effect.description }}</small>
        </b-dropdown-item>
      </b-dropdown>
    </b-field>
    <small>{{ selectedEffect.description }}</small>
    <div class="container">
      <b-field v-for="(param, i) in selectedEffect.params" v-bind:label="param.name" v-bind:key="i">
        <b-numberinput
          type="is-text"
          v-model.number="currentParams[param.id]"
          v-bind:min="param.minimum"
        ></b-numberinput>
      </b-field>
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
