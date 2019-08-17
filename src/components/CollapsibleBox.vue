<template>
  <div class="effect-box">
    <div
      class="effect-header"
      @click="collapsed = !collapsed"
    >{{ '[' + (collapsed ? '+' : '-') + '] ' }} {{ header }}</div>
    <div class="container" v-if="!collapsed">
      <slot></slot>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    header: String,
    collapsed: Boolean
  }
};
</script>

<style lang="scss" scoped>
@import "../scss/global.scss";

.effect-box {
  border: 2px solid $text;
  margin-bottom: 16px;
}

.effect-box:nth-child(n + 2):last-child {
  margin-bottom: 0;
}

.effect-header {
  background-color: $text;
  color: $background;
  font-family: "Space Mono", monospace;
  padding: 4px;
  text-transform: uppercase;
  user-select: none;
}

.effect-box,
.effect-header {
}

.effect-box:hover .effect-header {
  background-color: $accent-1;
}

.effect-box:hover {
  border-color: $accent-1;
}
</style>
