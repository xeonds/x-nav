<template>
    <h2>Fit/Gpx/Tcx2Json 转换工具</h2>
    <p>
        <span>
            <button @click="uploadFile">上传.fit文件</button>
            <button @click="uploadFile">上传.gpx文件</button>
            <button @click="uploadFile">上传.tcx文件</button>
            <button @click="exportJsonData">保存.json结果</button>
        </span>
    </p>
    <p v-if="processing">上传中</p>
    <p v-else>{{ data }}</p>
</template>

<script setup>
import { ref } from 'vue'
import { extractTracks } from './track';

const data = ref('')
const processing = ref(false);
const uploadFile = () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.onchange = async (e) => {
        const file = (e.target).files?.[0];
        if (!file) return;
        extractTracks(file)
            .then(res => data.value = res)
            .catch(err => data.value = err)
        processing.value = false;
    };
    input.click();
}

const exportJsonData = () => {
    const d = JSON.stringify(data.value);
    const blob = new Blob([d], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'converted-fit.json';
    a.click();
    URL.revokeObjectURL(url);
}
</script>