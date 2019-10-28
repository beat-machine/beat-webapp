<template>
  <div class="effect-selector">
    <div class="field">
      <descriptive-input fieldId="type" label="Type" :help="selectedEffect.description">
        <select id="type" v-model.number="selectedEffectIndex" v-on:change="updateParams()">
          <option v-for="(effect, i) in effects" v-bind:key="i" v-bind:value="i">{{ effect.name }}</option>
        </select>
      </descriptive-input>
    </div>
    <descriptive-input
      v-for="(param, i) in selectedEffect.params"
      :key="i"
      :fieldId="param.id"
      :label="param.name"
      :help="param['help']"
    >
      <input
        type="number"
        :id="param.id"
        :min="param.minimum"
        @change="propagateChanges"
        @input="propagateChanges"
        v-model.number="currentParams[param.id]"
      />
    </descriptive-input>
    <span v-if="!valid" class="error">{{ validationError }}</span>
  </div>
</template>

<script>
import DescriptiveInput from "./DescriptiveInput.vue";

export default {
  components: { DescriptiveInput },
  props: {
    effects: Array
  },
  data() {
    return {
      selectedEffectIndex: 0,
      currentParams: {},
      valid: true,
      validationError: ''
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
    },
    validate() {
      let error = this.selectedEffect.validate(this.currentParams)
      if (error === null) {
        this.valid = true;
        this.validationError = ""
      } else {
        this.valid = false;
        this.validationError = error;
      }
    },
    propagateChanges() {
      this.validate();
      this.$emit('input', {
        'effect': this.selectedEffect,
        'serialized': { type: this.selectedEffect.id, ...this.selectedEffect.serialize(this.currentParams) },
        ...this.$data
      });
    }
  },
  watch: {
    selectedEffectIndex() {
      this.updateParams();
      this.validate();
      this.propagateChanges();
    }
  },
  created() {
    this.updateParams();
    this.propagateChanges();
  }
};
</script>

<style lang="scss" scoped>
.error {
  color: var(--error);
}
</style>