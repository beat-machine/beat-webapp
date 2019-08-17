<template>
  <div class="field">
    <label :for="name">{{ label }}:</label>
    <slot></slot>
    <span v-if="help">{{ help }}</span>
  </div>
</template>

<script>
export default {
  props: {
    fieldId: String,
    label: String,
    help: String
  }
};
</script>

<style lang="scss" scoped>
@import "../scss/global.scss";

option {
  color: #000;
}

select,
input[type="number"] {
  font-family: "Space Mono", monospace;
  font-weight: bold;
  background-color: inherit;
  color: $primary-text;
  padding: 8px;
  border: 2px solid $text;
}

.label {
  margin-right: 10px;
}

.field {
  margin-bottom: 16px;
}

.field:nth-child(n + 2):last-child {
  margin-bottom: 0;
}

label {
  display: block;
  margin-bottom: 8px;
  font-size: 16pt;
  color: $primary-text;

  @media (min-width: 1400px) {
    display: inline-block;
    width: 180px;
  }
}

span {
  display: block;
  padding-top: 16px;

  @media (min-width: 1400px) {
    display: inline-block;
    margin-top: 0;
    margin-left: 16px;
  }
}
</style>
