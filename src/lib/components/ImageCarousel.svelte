<script lang="ts">
	import EmblaCarousel from 'embla-carousel';
	import { onMount } from 'svelte';

	let {
		images = [],
		onImageClick,
	}: {
		images: { url: string; caption: string }[];
		onImageClick?: (index: number) => void;
	} = $props();

	let emblaRef: HTMLDivElement;
	let emblaApi: ReturnType<typeof EmblaCarousel> | null = null;
	let selectedIndex = $state(0);
	let canScrollPrev = $state(false);
	let canScrollNext = $state(false);

	onMount(() => {
		if (!emblaRef || images.length === 0) return;

		const api = EmblaCarousel(emblaRef, {
			loop: images.length > 1,
			dragFree: false,
			containScroll: 'trimSnaps',
		});

		const onSelect = () => {
			selectedIndex = api.selectedScrollSnap();
			canScrollPrev = api.canScrollPrev();
			canScrollNext = api.canScrollNext();
		};

		api.on('select', onSelect);
		api.on('reInit', onSelect);
		onSelect();

		emblaApi = api;
		return () => api.destroy();
	});

	function scrollPrev() { emblaApi?.scrollPrev(); }
	function scrollNext() { emblaApi?.scrollNext(); }
	function scrollTo(index: number) { emblaApi?.scrollTo(index); }
</script>

{#if images.length > 0}
	<div class="group relative">
		<!-- Carousel viewport -->
		<div class="embla rounded-2xl bg-secondary/30" bind:this={emblaRef}>
			<div class="embla__container">
				{#each images as img, i}
					<div class="embla__slide">
						<button
							onclick={() => onImageClick?.(i)}
							class="block w-full cursor-zoom-in"
						>
							<img
								src={img.url}
								alt={img.caption}
								class="aspect-[4/3] w-full object-cover"
								loading={i === 0 ? 'eager' : 'lazy'}
							/>
						</button>
					</div>
				{/each}
			</div>
		</div>

		<!-- Prev/Next arrows (visible on hover, desktop) -->
		{#if images.length > 1}
			<button
				onclick={scrollPrev}
				class="absolute left-3 top-1/2 -translate-y-1/2 rounded-full bg-black/40 p-2.5 text-white opacity-0 backdrop-blur-sm transition-all duration-200 hover:bg-black/60 group-hover:opacity-100 max-md:hidden"
				aria-label="Previous photo"
			>
				<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" /></svg>
			</button>
			<button
				onclick={scrollNext}
				class="absolute right-3 top-1/2 -translate-y-1/2 rounded-full bg-black/40 p-2.5 text-white opacity-0 backdrop-blur-sm transition-all duration-200 hover:bg-black/60 group-hover:opacity-100 max-md:hidden"
				aria-label="Next photo"
			>
				<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" /></svg>
			</button>

			<!-- Dot indicators -->
			<div class="absolute bottom-3 left-1/2 flex -translate-x-1/2 gap-1.5">
				{#each images as _, i}
					<button
						onclick={() => scrollTo(i)}
						class="h-2 rounded-full transition-all duration-200 {selectedIndex === i ? 'w-6 bg-white shadow-sm' : 'w-2 bg-white/50 hover:bg-white/75'}"
						aria-label="Go to photo {i + 1}"
					/>
				{/each}
			</div>
		{/if}

		<!-- Photo counter -->
		{#if images.length > 1}
			<div class="absolute right-3 top-3 rounded-full bg-black/40 px-2.5 py-1 text-xs font-medium text-white backdrop-blur-sm">
				{selectedIndex + 1} / {images.length}
			</div>
		{/if}
	</div>
{:else}
	<!-- Empty state -->
	<div class="img-placeholder flex aspect-[4/3] items-center justify-center rounded-2xl">
		<div class="text-center text-muted-foreground">
			<svg class="mx-auto mb-2 h-12 w-12 opacity-40" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
				<path stroke-linecap="round" stroke-linejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Z" />
			</svg>
			<p class="text-sm">No photos yet</p>
		</div>
	</div>
{/if}
