import { createRouter, createWebHashHistory } from "vue-router";

const routes = [
    {
        path: "/",
        children: [
            { path: "/", component: () => import("./views/home.vue") },
            { path: "convert", component: () => import("./views/convert.vue") },
            { path: "track", component: () => import("./views/track.vue") },
        ],
    },
];

const router = createRouter({
    history: createWebHashHistory(),
    routes,
});

export default router;