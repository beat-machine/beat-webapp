<template>
  <div class="field" :class="{'disabled': disabled}">
    <label :for="fieldId" :class="{'stay-inline': inlineField}">{{ label }}:</label>
    <slot></slot>
    <span v-if="help">{{ help }}</span>
  </div>
</template>

<script>
export default {
  props: {
    fieldId: String,
    label: String,
    help: String,
    disabled: Boolean,
    inlineField: Boolean
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
  vertical-align: middle;
}

select,
input {
  margin-right: 20px;
}

input[type="number"] {
  width: 200px;
}

.field {
  margin-bottom: 16px;
}

.field:nth-child(n + 2):last-child {
  margin-bottom: 0;
}

label {
  display: block;
  font-size: 16pt;
  margin-bottom: 8px;
  color: $primary-text;

  @media (min-width: 1400px) {
    display: inline-block;
    margin-bottom: 0;
    vertical-align: middle;
    width: 180px;
  }
}

label.stay-inline {
  display: inline-block;
  margin-right: 16px;

  @media (min-width: 1400px) {
    margin-right: 0;
  }
}

.disabled label,
.disabled input {
  color: $disabled-text;
  border-color: $disabled-text;
}

.disabled label {
  text-decoration: line-through;
}

span {
  display: block;
  margin-top: 8px;

  @media (min-width: 1400px) {
    display: inline-block;
    margin-top: 10px;
    margin-bottom: 10px;
  }
}
</style>
