<template>
  <div class="circuit" aria-hidden="true">
    <svg viewBox="0 0 600 700" preserveAspectRatio="xMidYMid slice">
      <path class="trace" d="M40 120 H220 V60 H360" />
      <path class="trace" d="M0 220 H140 V300 H320 V220 H520" />
      <path class="trace" d="M80 400 H260 V480 H440" />
      <path class="trace" d="M300 40 V160 H460 V320" />
      <path class="trace" d="M180 560 H380 V640 H560" />
      <path class="trace" d="M460 380 H600" />
      <circle class="node" cx="220" cy="60" r="4" />
      <circle class="node" cx="360" cy="60" r="4" />
      <circle class="node" cx="320" cy="220" r="4" />
      <circle class="node" cx="460" cy="160" r="4" />
      <circle class="node" cx="260" cy="480" r="4" />
      <circle class="node" cx="380" cy="640" r="4" />
      <circle class="node" cx="460" cy="380" r="4" />
      <circle class="node" cx="140" cy="300" r="4" />
    </svg>
  </div>
</template>

<style scoped>
.circuit {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
}
.circuit svg {
  position: absolute;
  right: -4%;
  top: -30%;
  width: 70%;
  height: 170%;
  opacity: 0.5;
}
.circuit .trace {
  stroke: var(--accent);
  fill: none;
  stroke-width: 1;
  opacity: 0.28;
}
.circuit .node {
  fill: var(--accent);
}
@media (prefers-reduced-motion: no-preference) {
  .circuit .node {
    animation: pulse 3.4s ease-in-out infinite;
  }
  .circuit .node:nth-child(3n) {
    animation-delay: 1.1s;
  }
  .circuit .node:nth-child(3n + 1) {
    animation-delay: 2.2s;
  }
}
@keyframes pulse {
  0%,
  100% {
    opacity: 0.35;
  }
  50% {
    opacity: 1;
  }
}
@media (max-width: 900px) {
  .circuit svg {
    opacity: 0.28;
  }
}
</style>
