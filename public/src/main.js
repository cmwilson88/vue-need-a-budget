import Vue from 'vue'
import VueRouter from 'vue-router'
import App from './App.vue'

import {routes} from './routes/routes.js'

Vue.use(VueRouter)

const router = new VueRouter({
	routes: routes
})

new Vue({
  el: '#app',
  router: router,
  render: h => h(App)
})