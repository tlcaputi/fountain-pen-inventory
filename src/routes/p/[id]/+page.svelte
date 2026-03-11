<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { page } from '$app/state';
	import ImageCarousel from '$lib/components/ImageCarousel.svelte';

	type Pen = Record<string, unknown>;
	type Photo = { id: string; photo_url: string; caption: string | null; sort_order: number };

	let pen = $state<Pen | null>(null);
	let photos = $state<Photo[]>([]);
	let loading = $state(true);
	let notFound = $state(false);

	// Lightbox
	let lightboxOpen = $state(false);
	let lightboxIdx = $state(0);

	$effect(() => { loadPen(); });

	async function loadPen() {
		loading = true;
		const id = page.params.id;
		const { data } = await supabase.from('pens').select('*').eq('id', id).eq('is_public', true).single();
		if (!data) {
			// Also check if the owner's collection is public
			const { data: data2 } = await supabase.from('pens').select('*').eq('id', id).single();
			if (data2) {
				pen = data2;
			} else {
				notFound = true;
				loading = false;
				return;
			}
		} else {
			pen = data;
		}

		const { data: photoData } = await supabase
			.from('pen_photos')
			.select('id, photo_url, caption, sort_order')
			.eq('pen_id', id)
			.order('sort_order');
		if (photoData) photos = photoData;
		loading = false;
	}

	let allImages = $derived.by(() => {
		const imgs: { url: string; caption: string }[] = [];
		if (pen?.photo_closed_url) imgs.push({ url: pen.photo_closed_url as string, caption: 'Main photo' });
		for (const p of photos) {
			if (!imgs.find(i => i.url === p.photo_url)) {
				imgs.push({ url: p.photo_url, caption: p.caption ?? '' });
			}
		}
		return imgs;
	});

	function val(key: string): string { return (pen?.[key] as string) ?? ''; }
	function hasVal(key: string): boolean { const v = pen?.[key]; return v != null && v !== ''; }

	function openLightbox(idx: number) {
		lightboxIdx = idx;
		lightboxOpen = true;
	}

	let keyFacts = $derived(
		[
			['Maker', val('manufacturer')],
			['Year', val('year_made')],
			['Type', val('pen_type')],
			['Color', val('color')],
			['Filler', val('filler')],
			['Nib', val('nib_stroke')],
			['Nib Material', val('nib_material')],
		].filter(([, v]) => v) as [string, string][]
	);

	// Expandable sections
	let showPhysical = $derived(!!(pen && (val('primary_material') || val('body_material') || val('size') || val('length') || val('diameter') || val('weight') || val('cap_type'))));
	let showReview = $derived(!!(pen && (val('first_impression') || val('appearance') || val('design') || val('nib_review') || val('filling_system_review') || val('cost_and_value') || val('conclusion'))));
</script>

<svelte:head>
	<title>{pen ? `${val('model') || 'Pen'} — PenVault` : 'PenVault'}</title>
</svelte:head>

<!-- Lightbox -->
{#if lightboxOpen && allImages.length > 0}
	<div
		class="fixed inset-0 z-[100] flex items-center justify-center bg-black/95 animate-fade-in"
		onclick={() => lightboxOpen = false}
		onkeydown={(e) => {
			if (e.key === 'Escape') lightboxOpen = false;
			if (e.key === 'ArrowRight') lightboxIdx = (lightboxIdx + 1) % allImages.length;
			if (e.key === 'ArrowLeft') lightboxIdx = (lightboxIdx - 1 + allImages.length) % allImages.length;
		}}
		role="dialog"
		tabindex="-1"
	>
		<button onclick={() => lightboxOpen = false} class="absolute right-4 top-4 z-10 rounded-full bg-white/10 p-2.5 text-white/80 transition-colors hover:bg-white/20 hover:text-white">
			<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
		</button>
		{#if allImages.length > 1}
			<button onclick={(e) => { e.stopPropagation(); lightboxIdx = (lightboxIdx - 1 + allImages.length) % allImages.length; }} class="absolute left-4 top-1/2 z-10 -translate-y-1/2 rounded-full bg-white/10 p-3 text-white/80 transition-colors hover:bg-white/20 hover:text-white">
				<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" /></svg>
			</button>
		{/if}
		<img src={allImages[lightboxIdx].url} alt={allImages[lightboxIdx].caption} class="max-h-[85vh] max-w-[90vw] rounded-lg object-contain animate-scale-in" onclick={(e) => e.stopPropagation()} />
		{#if allImages.length > 1}
			<button onclick={(e) => { e.stopPropagation(); lightboxIdx = (lightboxIdx + 1) % allImages.length; }} class="absolute right-4 top-1/2 z-10 -translate-y-1/2 rounded-full bg-white/10 p-3 text-white/80 transition-colors hover:bg-white/20 hover:text-white">
				<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" /></svg>
			</button>
		{/if}
		<div class="absolute bottom-6 left-1/2 -translate-x-1/2 text-center">
			<p class="text-sm font-medium text-white/90">{lightboxIdx + 1} / {allImages.length}</p>
		</div>
	</div>
{/if}

<div class="mx-auto max-w-5xl px-4 py-8 md:px-6 lg:py-12">
	{#if loading}
		<div class="flex justify-center py-20">
			<div class="h-8 w-8 animate-spin rounded-full border-3 border-primary border-t-transparent"></div>
		</div>
	{:else if notFound || !pen}
		<div class="flex flex-col items-center justify-center py-20 text-center">
			<svg class="mb-4 h-16 w-16 text-muted-foreground/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z" /></svg>
			<h2 class="text-lg font-medium text-foreground">Pen not found</h2>
			<p class="mt-1 text-sm text-muted-foreground">This pen may not be shared publicly</p>
			<a href="/" class="mt-4 rounded-xl bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">Go to PenVault</a>
		</div>
	{:else}
		<!-- Header -->
		<div class="mb-6 flex items-center gap-3">
			<a href="/" class="flex items-center gap-2 text-muted-foreground transition-colors hover:text-foreground">
				<div class="flex h-7 w-7 items-center justify-center rounded-lg bg-primary text-[10px] font-bold text-primary-foreground">PV</div>
				<span class="font-serif text-sm font-bold">PenVault</span>
			</a>
			<span class="text-muted-foreground/40">/</span>
			<h1 class="font-serif text-xl font-bold text-foreground md:text-2xl">{val('model') || 'Untitled Pen'}</h1>
		</div>

		<!-- Two-column layout -->
		<div class="mb-8 grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)]">
			<!-- Photos -->
			<div>
				<ImageCarousel images={allImages} onImageClick={openLightbox} />
			</div>

			<!-- Details -->
			<div class="space-y-4">
				{#if keyFacts.length > 0}
					<div class="rounded-2xl border border-border bg-card p-5 shadow-sm">
						<div class="space-y-3">
							{#each keyFacts as [label, value]}
								<div class="flex items-baseline justify-between gap-4">
									<span class="text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</span>
									<span class="text-right text-foreground">{value}</span>
								</div>
							{/each}
						</div>
					</div>
				{/if}

				{#if val('comments')}
					<div class="rounded-2xl border border-border bg-card p-5 shadow-sm">
						<h3 class="mb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Notes</h3>
						<p class="whitespace-pre-wrap text-sm leading-relaxed text-foreground">{val('comments')}</p>
					</div>
				{/if}

				{#if val('description')}
					<div class="rounded-2xl border border-border bg-card p-5 shadow-sm">
						<h3 class="mb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Description</h3>
						<p class="whitespace-pre-wrap text-sm leading-relaxed text-foreground">{val('description')}</p>
					</div>
				{/if}
			</div>
		</div>

		<!-- Physical details -->
		{#if showPhysical}
			<section class="mb-3 overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
				<div class="px-5 py-4">
					<h2 class="font-serif text-base font-semibold text-foreground">Physical Details</h2>
				</div>
				<div class="border-t border-border p-5">
					<div class="grid gap-x-8 gap-y-3 sm:grid-cols-2 lg:grid-cols-3">
						{#each [
							['primary_material', 'Material'], ['body_material', 'Body Material'], ['size', 'Size'],
							['length', 'Length'], ['length_posted', 'Length (posted)'], ['diameter', 'Diameter'],
							['weight', 'Weight'], ['cap_type', 'Cap Type'], ['nib_flex', 'Nib Flex'], ['nib_modification', 'Nib Modification'],
						] as [key, label]}
							{#if hasVal(key)}
								<div class="flex items-baseline justify-between gap-3">
									<span class="text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</span>
									<span class="text-right text-sm text-foreground">{val(key)}</span>
								</div>
							{/if}
						{/each}
					</div>
				</div>
			</section>
		{/if}

		<!-- Review -->
		{#if showReview}
			<section class="mb-3 overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
				<div class="px-5 py-4">
					<h2 class="font-serif text-base font-semibold text-foreground">Review</h2>
				</div>
				<div class="border-t border-border p-5 space-y-5">
					{#each [
						['first_impression', 'First Impression', 'first_impression_rating'],
						['appearance', 'Appearance', 'appearance_rating'],
						['design', 'Design', 'design_rating'],
						['nib_review', 'Nib', 'nib_rating'],
						['filling_system_review', 'Filling System', 'filling_system_rating'],
						['cost_and_value', 'Cost & Value', 'cost_and_value_rating'],
					] as [field, label, ratingField]}
						{#if hasVal(field) || hasVal(ratingField)}
							<div>
								<div class="flex items-center gap-2">
									<h4 class="text-sm font-semibold text-foreground">{label}</h4>
									{#if hasVal(ratingField)}
										<span class="inline-flex items-center gap-1 rounded-full bg-accent/15 px-2.5 py-0.5 text-xs font-semibold text-accent">
											<svg class="h-3 w-3" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" /></svg>
											{val(ratingField)}/10
										</span>
									{/if}
								</div>
								{#if hasVal(field)}<p class="mt-1.5 whitespace-pre-wrap text-sm leading-relaxed text-muted-foreground">{val(field)}</p>{/if}
							</div>
						{/if}
					{/each}
					{#if hasVal('conclusion')}
						<div>
							<h4 class="text-sm font-semibold text-foreground">Conclusion</h4>
							<p class="mt-1.5 whitespace-pre-wrap text-sm leading-relaxed text-muted-foreground">{val('conclusion')}</p>
						</div>
					{/if}
				</div>
			</section>
		{/if}

		<!-- Footer -->
		<div class="mt-8 text-center">
			<a href="/" class="inline-flex items-center gap-2 text-xs text-muted-foreground/60 transition-colors hover:text-muted-foreground">
				<div class="flex h-5 w-5 items-center justify-center rounded bg-primary/80 text-[8px] font-bold text-primary-foreground">PV</div>
				Shared via PenVault
			</a>
		</div>
	{/if}
</div>
