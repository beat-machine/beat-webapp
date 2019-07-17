<template>
  <div class="effect-selector">
    <div class="field">
      <label for="type">Type:</label>
      <select id="type" v-model="selectedEffectIndex" v-on:change="updateParams()">
        <option v-for="(effect, i) in effects" v-bind:key="i" v-bind:value="i">{{ effect.name }}</option>
      </select>
      <span>{{ selectedEffect.description }}</span>
    </div>
    <div class="field" v-for="(param, i) in selectedEffect.params" v-bind:key="i">
      <label :for="param.id">{{ param.name }}:</label>
      <input
        :id="param.id"
        type="number"
        v-model.number="currentParams[param.id]"
        v-bind:min="param.minimum"
      />
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

<style lang="scss">
.effect-selector {
  padding: 16px;
}

.field {
  margin-bottom: 16px;
}

.param-label {
  margin-right: 10px;
}

.field:last-child {
  margin-bottom: 0;
}

label {
  display: block;
  margin-bottom: 8px;
  font-size: 16pt;

  @media (min-width: 1400px) {
    display: inline-block;
    width: 180px;
  }
}

span {
  display: block;
  margin-top: 16px;

  @media (min-width: 1400px) {
    display: inline-block;
    margin-top: 0;
    margin-left: 16px;
  }
}
</style>
