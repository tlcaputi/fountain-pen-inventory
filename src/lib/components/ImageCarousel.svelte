<script lang="ts">
	import EmblaCarousel from 'embla-carousel';
	import { tick } from 'svelte';

	let {
		images = [],
		onImageClick,
		onSelect: onSelectCallback,
	}: {
		images: { url: string; caption: string }[];
		onImageClick?: (index: number) => void;
		onSelect?: (index: number) => void;
	} = $props();

	let emblaRef: HTMLDivElement | undefined = $state();
	let emblaApi: ReturnType<typeof EmblaCarousel> | null = null;
	let selectedIndex = $state(0);

	// Re-initialize carousel when images change or ref becomes available
	$effect(() => {
		const imgCount = images.length;
		const ref = emblaRef;

		if (!ref || imgCount === 0) {
			if (emblaApi) { emblaApi.destroy(); emblaApi = null; }
			return;
		}

		// Need to tick so Svelte renders the slides first
		tick().then(() => {
			if (emblaApi) emblaApi.destroy();

			const api = EmblaCarousel(ref, {
				loop: imgCount > 1,
				dragFree: false,
				containScroll: 'trimSnaps',
			});

			const onSelect = () => {
				selectedIndex = api.selectedScrollSnap();
				onSelectCallback?.(selectedIndex);
			};

			api.on('select', onSelect);
			api.on('reInit', onSelect);
			onSelect();

			emblaApi = api;
		});

		return () => {
			if (emblaApi) { emblaApi.destroy(); emblaApi = null; }
		};
	});

	function scrollPrev() { emblaApi?.scrollPrev(); }
	function scrollNext() { emblaApi?.scrollNext(); }
	function scrollTo(index: number) { emblaApi?.scrollTo(index); }
</script>

{#if images.length > 0}
	<div class="space-y-3">
		<!-- Main carousel -->
		<div class="group relative">
			<div class="embla rounded-2xl" bind:this={emblaRef}>
				<div class="embla__container">
					{#each images as img, i}
						<div class="embla__slide">
							<button
								onclick={() => onImageClick?.(i)}
								class="block w-full cursor-zoom-in"
							>
								<div class="flex aspect-[4/3] items-center justify-center bg-black">
									<img
										src={img.url}
										alt={img.caption}
										class="max-h-full max-w-full object-contain"
										loading={i === 0 ? 'eager' : 'lazy'}
									/>
								</div>
							</button>
						</div>
					{/each}
				</div>
			</div>

			<!-- Prev/Next arrows — always visible on desktop when multiple images -->
			{#if images.length > 1}
				<button
					onclick={scrollPrev}
					class="absolute left-2 top-1/2 -translate-y-1/2 rounded-full bg-black/50 p-2 text-white shadow-lg transition-all hover:bg-black/70 sm:left-3 sm:p-3"
					aria-label="Previous photo"
				>
					<svg class="h-4 w-4 sm:h-5 sm:w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" /></svg>
				</button>
				<button
					onclick={scrollNext}
					class="absolute right-2 top-1/2 -translate-y-1/2 rounded-full bg-black/50 p-2 text-white shadow-lg transition-all hover:bg-black/70 sm:right-3 sm:p-3"
					aria-label="Next photo"
				>
					<svg class="h-4 w-4 sm:h-5 sm:w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" /></svg>
				</button>

				<!-- Counter badge -->
				<div class="absolute right-2 top-2 rounded-full bg-black/50 px-2 py-0.5 text-xs font-semibold text-white sm:right-3 sm:top-3 sm:px-2.5 sm:py-1">
					{selectedIndex + 1} / {images.length}
				</div>
			{/if}
		</div>

		<!-- Thumbnail strip -->
		{#if images.length > 1}
			<div class="flex gap-2 overflow-x-auto pb-1">
				{#each images as img, i}
					<button
						onclick={() => scrollTo(i)}
						class="h-14 w-14 flex-shrink-0 overflow-hidden rounded-lg border-2 transition-all sm:h-16 sm:w-16 {selectedIndex === i ? 'border-primary ring-2 ring-primary/30' : 'border-transparent opacity-60 hover:opacity-100'}"
					>
						<img src={img.url} alt={img.caption} class="h-full w-full object-cover" loading="lazy" />
					</button>
				{/each}
			</div>
		{/if}
	</div>
{:else}
	<div class="img-placeholder flex aspect-[4/3] items-center justify-center rounded-2xl">
		<div class="text-center text-muted-foreground">
			<svg class="mx-auto mb-2 h-12 w-12 opacity-40" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
				<path stroke-linecap="round" stroke-linejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Z" />
			</svg>
			<p class="text-sm">No photos yet</p>
		</div>
	</div>
{/if}
