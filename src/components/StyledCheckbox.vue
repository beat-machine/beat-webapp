<template>
  <div class="styled-checkbox" :class="{ checked: value }" @click="toggleState">
    <input type="checkbox" :name="name" :id="id" v-model="value" />
  </div>
</template>

<script>
export default {
  props: {
    name: String,
    id: String
  },
  data() {
    return {
      value: false
    };
  },
  methods: {
    toggleState() {
      this.value = !this.value;
      this.$emit("input", this.value);
    }
  }
};
</script>

<style lang="scss" scoped>
@import "../scss/global.scss";

.styled-checkbox {
  display: inline-block;
  width: 24px;
  height: 24px;
  vertical-align: middle;
  border: 2px solid $text;
  margin-right: 16px;
}

.checked {
  background-color: $text;
  color: $background;
}

input[type="checkbox"] {
  display: none;
}
</style>
