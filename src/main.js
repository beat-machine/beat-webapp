import Vue from 'vue'
import App from './App.vue'

import 'normalize.css'

// You may be wondering to yourself: does this site really need Vue?
// The answer: not really. It was cool to learn though.

new Vue({
  render: h => h(App),
}).$mount('#app')
