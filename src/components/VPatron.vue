<template>
    <div class="patron">
        <h2>{{ name }}</h2>
        <div class="links">
            <div class="link">
                <a :href="links.youtube">
                    <youtube-icon class="social-icon"></youtube-icon>
                </a>
            </div>
        </div>
    </div>
</template>

<script>
import { YoutubeIcon } from 'vue-feather-icons';

export default {
    props: {
        name: String,
        tier: Number,
        links: Object
    },
    components: {
        YoutubeIcon
    }
}
</script>

<style lang="scss">
h2 {
    color: $primary-text;
    margin-bottom: 10px;
    margin-top: 10px;
}

.patron {
    text-align: left;
    @media (min-width: 1400px) {
        width: 32%;
    }
}

.social-icon {
    color: $primary-text;
}
</style>