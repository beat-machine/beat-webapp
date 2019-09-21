<template>
  <div class="styled-upload">
    <input
      type="button"
      value="Upload"
      @click="$refs.file.click()"
    />
    <span v-if="file">
        {{ file.name }}
    </span>
    <span v-else>
        No file selected.
    </span>
    <input ref="file" type="file" :accept="accept" @change="onFileChanged"/>
  </div>
</template>

<script>
export default {
    props: {
        value: File,
        accept: String
    },
    data() {
        return {
            file: null
        }
    },
    methods: {
        onFileChanged(e) {
            this.file = e.target.files[0]
            this.$emit('input', this.file)
        }
    }
};
</script>

<style lang="scss" scoped>
.styled-upload {
    display: inline-block;
}

span {
    margin-left: 16px;
    margin-right: 16px;
}

input[type="file"] {
    display: none;
}
</style>