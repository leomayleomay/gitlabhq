<script>
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    TimeagoTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    artifact: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isExpired() {
      return this.artifact.expired;
    },
    // Only when the key is `false` we can render this block
    willExpire() {
      return this.artifact.expired === false;
    },
  },
};
</script>
<template>
  <div class="block">
    <div class="title">
      {{ s__('Job|Job artifacts') }}
    </div>

    <p
      v-if="isExpired"
      class="js-artifacts-removed build-detail-row"
    >
      {{ s__('Job|The artifacts were removed') }}
    </p>

    <p
      v-else-if="willExpire"
      class="js-artifacts-will-be-removed build-detail-row"
    >
      {{ s__('Job|The artifacts will be removed in') }}
    </p>

    <timeago-tooltip
      v-if="artifact.expire_at"
      :time="artifact.expire_at"
    />

    <div
      class="btn-group d-flex"
      role="group"
    >
      <a
        v-if="artifact.keep_path"
        :href="artifact.keep_path"
        class="js-keep-artifacts btn btn-sm btn-default"
        data-method="post"
      >
        {{ s__('Job|Keep') }}
      </a>

      <a
        v-if="artifact.download_path"
        :href="artifact.download_path"
        class="js-download-artifacts btn btn-sm btn-default"
        download
        rel="nofollow"
      >
        {{ s__('Job|Download') }}
      </a>

      <a
        v-if="artifact.browse_path"
        :href="artifact.browse_path"
        class="js-browse-artifacts btn btn-sm btn-default"
      >
        {{ s__('Job|Browse') }}
      </a>
    </div>
  </div>
</template>
