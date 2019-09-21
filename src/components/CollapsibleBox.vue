<template>
  <div class="effect-box">
    <div
      class="effect-header"
      @click="collapsed = !collapsed"
    >{{ '[' + (collapsed ? '+' : '-') + '] ' }} {{ header }}</div>
    <div class="container" v-show="!collapsed">
      <slot></slot>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    header: String,
    startCollapsed: Boolean
  },
  data() {
    return {
      collapsed: this.startCollapsed
    };
  }
};
</script>

<style lang="scss" scoped>
.container {
  padding: 16px;
}

.effect-box {
  border: 2px solid $text;
  margin-bottom: 16px;

  transition: border-color 0.2s $fast-ease;
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

  transition: background-color 0.2s $fast-ease;
}

.effect-box:hover .effect-header {
  background-color: $accent-1;
}

.effect-box:hover {
  border-color: $accent-1;
}
</style>
