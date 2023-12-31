<script setup lang="ts">
import { computed, ref } from 'vue';

import { Network, networkName, useEthereumStore } from '../stores/ethereum';
import JazzIcon from './JazzIcon.vue';
import { abbrAddr } from '@/utils/utils';
import { useMedia } from '@/utils/useMediaQuery';

const eth = useEthereumStore();

const netName = computed(() => networkName(eth.network));
const unkNet = computed(() => eth.network === Network.Unknown);

const connecting = ref(false);
const showingConnecting = ref(false);

async function connectWallet() {
  if (connecting.value) return;
  connecting.value = true;
  try {
    setTimeout(() => {
      showingConnecting.value = connecting.value;
    }, 300);
    await eth.connect();
  } finally {
    connecting.value = false;
  }
}

const isXlScreen = useMedia('(min-width: 1280px)');
</script>

<template>
  <div :class="{ 'cursor-default': !!eth.address }" class="account-picker" @click="connectWallet">
    <span class="account-picker-content" v-if="!connecting && eth.address">
      <JazzIcon :size="isXlScreen ? 60 : 30" :address="eth.address" />
      <span class="font-mono font-bold">
        <abbr :title="eth.address" class="block no-underline">{{ abbrAddr(eth.address) }}</abbr>
        <span v-if="isXlScreen" class="font-normal" :class="{ 'unk-net': unkNet }">{{
          netName
        }}</span>
      </span>
    </span>
    <span class="account-picker-content" v-else>
      <span>
        <span v-if="showingConnecting">Connecting…</span>
        <span v-else>Connect Wallet</span>
      </span>
    </span>
  </div>
</template>

<style lang="postcss" scoped>
.account-picker-content {
  @apply inline-flex items-center gap-2 xl:gap-6;
}

.account-picker {
  @apply inline-flex items-center border border-gray-900 rounded-xl bg-white border-primaryDark h-12 p-2 xl:p-4 xl:fixed xl:right-10 xl:top-28 xl:h-auto;
  border-width: 3px;
  border-style: solid;

  @media (max-width: 1280px) {
    border-width: 1px;
  }
}

span {
  @apply text-base text-primaryDark text-right xl:text-xl;
}

.unk-net {
  @apply text-red-500 underline decoration-wavy decoration-1;
}
</style>
