<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { page } from '$app/state';
	import { goto } from '$app/navigation';
	import ImageCarousel from '$lib/components/ImageCarousel.svelte';

	type Pen = Record<string, unknown>;
	type Photo = { id: string; photo_url: string; caption: string | null; sort_order: number };

	let pen = $state<Pen | null>(null);
	let photos = $state<Photo[]>([]);
	let loading = $state(true);
	let saving = $state(false);
	let deleting = $state(false);
	let error = $state('');
	let success = $state('');
	let editing = $state(false);

	// Lightbox
	let lightboxOpen = $state(false);
	let lightboxIdx = $state(0);

	// Expandable sections
	let showPhysical = $state(false);
	let showCondition = $state(false);
	let showPurchase = $state(false);
	let showReview = $state(false);

	let form = $state<Pen>({});

	$effect(() => { loadPen(); });

	async function loadPen() {
		loading = true;
		const id = page.params.id;
		const { data } = await supabase.from('pens').select('*').eq('id', id).single();
		if (data) {
			pen = data;
			form = { ...data };
			showPhysical = !!(data.primary_material || data.body_material || data.size || data.length || data.diameter || data.weight || data.cap_type);
			showCondition = !!(data.condition_rating || data.new_used || data.repair_required);
			showPurchase = !!(data.purchase_price || data.purchase_date || data.purchased_from || data.selling_price);
			showReview = !!(data.first_impression || data.appearance || data.design || data.nib_review || data.filling_system_review || data.cost_and_value || data.conclusion);
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

	async function handleSave() {
		saving = true;
		error = '';
		success = '';
		const data: Pen = {};
		const fields = [
			'model', 'manufacturer', 'description', 'pen_type', 'year_made', 'color',
			'primary_material', 'body_material', 'size', 'length', 'length_posted',
			'diameter', 'weight', 'cap_type', 'nib_stroke', 'nib_material', 'nib_flex',
			'nib_modification', 'filler', 'new_used', 'repair_required', 'repaired_by',
			'comments', 'miscellaneous', 'purchased_from', 'sold_to',
			'photo_closed_url', 'photo_open_url', 'photo_posted_url', 'photo_nib_url', 'photo_converter_url',
			'photo_closed_caption', 'photo_open_caption', 'photo_posted_caption', 'photo_nib_caption', 'photo_converter_caption',
			'first_impression', 'appearance', 'design', 'nib_review', 'filling_system_review',
			'cost_and_value', 'conclusion', 'purchase_price_currency', 'purchase_date', 'selling_date', 'valuation_date',
		];
		const numFields = [
			'condition_rating', 'repair_cost', 'purchase_price', 'shipping_cost',
			'retail_price', 'selling_price', 'current_value', 'quantity',
			'first_impression_rating', 'appearance_rating', 'design_rating',
			'nib_rating', 'filling_system_rating', 'cost_and_value_rating',
		];
		for (const f of fields) data[f] = form[f] || null;
		for (const f of numFields) data[f] = form[f] ?? null;
		data.updated_at = new Date().toISOString();

		const { error: err } = await supabase.from('pens').update(data).eq('id', pen!.id);
		if (err) { error = err.message; }
		else {
			success = 'Changes saved';
			pen = { ...pen, ...data };
			editing = false;
			setTimeout(() => success = '', 3000);
		}
		saving = false;
	}

	async function handleDelete() {
		if (!confirm('Delete this pen permanently? This cannot be undone.')) return;
		deleting = true;
		await supabase.from('pen_photos').delete().eq('pen_id', pen!.id);
		const { error: err } = await supabase.from('pens').delete().eq('id', pen!.id);
		if (err) { error = err.message; deleting = false; }
		else goto('/app/pens');
	}

	function openLightbox(idx: number) {
		lightboxIdx = idx;
		lightboxOpen = true;
	}

	// Key facts to display
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
</script>

<!-- Toast notifications -->
{#if success}
	<div class="toast-enter fixed right-4 top-4 z-[200] flex items-center gap-2 rounded-xl bg-success px-4 py-3 text-sm font-medium text-white shadow-lg">
		<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" /></svg>
		{success}
	</div>
{/if}
{#if error}
	<div class="toast-enter fixed right-4 top-4 z-[200] flex items-center gap-2 rounded-xl bg-destructive px-4 py-3 text-sm font-medium text-white shadow-lg">
		<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z" /></svg>
		{error}
		<button onclick={() => error = ''} class="ml-1 opacity-70 hover:opacity-100">&times;</button>
	</div>
{/if}

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
		<!-- Close -->
		<button onclick={() => lightboxOpen = false} class="absolute right-4 top-4 z-10 rounded-full bg-white/10 p-2.5 text-white/80 transition-colors hover:bg-white/20 hover:text-white">
			<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
		</button>

		<!-- Prev -->
		{#if allImages.length > 1}
			<button
				onclick={(e) => { e.stopPropagation(); lightboxIdx = (lightboxIdx - 1 + allImages.length) % allImages.length; }}
				class="absolute left-4 top-1/2 z-10 -translate-y-1/2 rounded-full bg-white/10 p-3 text-white/80 transition-colors hover:bg-white/20 hover:text-white"
			>
				<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" /></svg>
			</button>
		{/if}

		<!-- Image -->
		<img
			src={allImages[lightboxIdx].url}
			alt={allImages[lightboxIdx].caption}
			class="max-h-[85vh] max-w-[90vw] rounded-lg object-contain animate-scale-in"
			onclick={(e) => e.stopPropagation()}
		/>

		<!-- Next -->
		{#if allImages.length > 1}
			<button
				onclick={(e) => { e.stopPropagation(); lightboxIdx = (lightboxIdx + 1) % allImages.length; }}
				class="absolute right-4 top-1/2 z-10 -translate-y-1/2 rounded-full bg-white/10 p-3 text-white/80 transition-colors hover:bg-white/20 hover:text-white"
			>
				<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" /></svg>
			</button>
		{/if}

		<!-- Counter + caption -->
		<div class="absolute bottom-6 left-1/2 -translate-x-1/2 text-center">
			<p class="text-sm font-medium text-white/90">{lightboxIdx + 1} / {allImages.length}</p>
			{#if allImages[lightboxIdx].caption && allImages[lightboxIdx].caption !== 'Main photo'}
				<p class="mt-1 text-xs text-white/60">{allImages[lightboxIdx].caption}</p>
			{/if}
		</div>
	</div>
{/if}

{#if loading}
	<!-- Skeleton -->
	<div class="mx-auto max-w-6xl animate-fade-in">
		<div class="mb-6 flex items-center gap-3">
			<div class="skeleton h-9 w-20 rounded-lg"></div>
			<div class="skeleton h-8 w-48"></div>
		</div>
		<div class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)]">
			<div class="skeleton aspect-[4/3] rounded-2xl"></div>
			<div class="space-y-4">
				<div class="skeleton h-6 w-32"></div>
				<div class="skeleton h-4 w-48"></div>
				<div class="skeleton h-4 w-40"></div>
				<div class="skeleton h-4 w-36"></div>
			</div>
		</div>
	</div>
{:else if pen}
	<div class="mx-auto max-w-6xl animate-slide-up">
		<!-- Header -->
		<div class="mb-6 flex items-center justify-between gap-4">
			<div class="flex items-center gap-3">
				<a href="/app/pens" class="group flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-sm text-muted-foreground transition-all hover:border-primary hover:bg-primary/5 hover:text-primary">
					<svg class="h-4 w-4 transition-transform group-hover:-translate-x-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" /></svg>
					Back
				</a>
				<h1 class="font-serif text-xl font-bold text-foreground md:text-2xl">{val('model') || 'Untitled Pen'}</h1>
			</div>
			<div class="flex items-center gap-2">
				{#if !editing}
					<button
						onclick={() => { editing = true; form = { ...pen }; }}
						class="inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-sm transition-all hover:bg-primary/90 hover:shadow-md active:scale-[0.98]"
					>
						<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
						<span class="hidden sm:inline">Edit</span>
					</button>
				{:else}
					<button
						onclick={handleSave}
						disabled={saving}
						class="inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-sm transition-all hover:bg-primary/90 disabled:opacity-50"
					>
						{#if saving}
							<div class="h-4 w-4 animate-spin rounded-full border-2 border-primary-foreground border-t-transparent"></div>
						{/if}
						{saving ? 'Saving...' : 'Save'}
					</button>
					<button
						onclick={() => { editing = false; form = { ...pen }; error = ''; }}
						class="rounded-xl border border-border px-4 py-2 text-sm text-muted-foreground transition-colors hover:bg-secondary hover:text-foreground"
					>
						Cancel
					</button>
				{/if}
			</div>
		</div>

		<!-- Two-column hero -->
		<div class="mb-8 grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)]">
			<!-- Left: Photo Carousel -->
			<div>
				<ImageCarousel images={allImages} onImageClick={openLightbox} />
			</div>

			<!-- Right: Key details -->
			<div class="space-y-4">
				{#if !editing}
					<!-- Key facts -->
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

							{#if pen?.purchase_price != null}
								<div class="mt-4 flex items-baseline gap-2 border-t border-border pt-4">
									<span class="text-2xl font-bold text-foreground">{val('purchase_price_currency') || 'USD'}{pen.purchase_price}</span>
									{#if val('purchase_date')}
										<span class="text-sm text-muted-foreground">purchased {val('purchase_date')}</span>
									{/if}
								</div>
							{/if}
						</div>
					{/if}

					<!-- Notes -->
					{#if val('comments')}
						<div class="rounded-2xl border border-border bg-card p-5 shadow-sm">
							<h3 class="mb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Notes</h3>
							<p class="whitespace-pre-wrap text-sm leading-relaxed text-foreground">{val('comments')}</p>
						</div>
					{/if}

					<!-- Description -->
					{#if val('description')}
						<div class="rounded-2xl border border-border bg-card p-5 shadow-sm">
							<h3 class="mb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Description</h3>
							<p class="whitespace-pre-wrap text-sm leading-relaxed text-foreground">{val('description')}</p>
						</div>
					{/if}
				{:else}
					<!-- Edit mode: Key fields -->
					<div class="rounded-2xl border border-border bg-card p-5 shadow-sm">
						<div class="grid gap-4 sm:grid-cols-2">
							{#each [
								['model', 'Model'],
								['manufacturer', 'Manufacturer'],
								['pen_type', 'Type'],
								['year_made', 'Year Made'],
								['color', 'Color'],
								['filler', 'Filling System'],
								['nib_stroke', 'Nib / Stroke'],
								['nib_material', 'Nib Material'],
							] as [key, label]}
								<div>
									<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</label>
									<input type="text" bind:value={form[key]} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring" />
								</div>
							{/each}
						</div>
					</div>

					<!-- Notes -->
					<div class="rounded-2xl border border-border bg-card p-5 shadow-sm">
						<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Notes</label>
						<textarea bind:value={form.comments} rows="3" class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
					</div>
				{/if}
			</div>
		</div>

		<!-- Expandable sections -->
		<div class="space-y-3">
			<!-- Physical Details -->
			{#if showPhysical || editing}
				<section class="overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
					<button onclick={() => showPhysical = !showPhysical} class="flex w-full items-center justify-between px-5 py-4 transition-colors hover:bg-secondary/30">
						<h2 class="font-serif text-base font-semibold text-foreground">Physical Details</h2>
						<svg class="h-5 w-5 text-muted-foreground transition-transform duration-300 {showPhysical ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" /></svg>
					</button>
					<div class="section-expand" data-open={showPhysical}>
						<div>
							<div class="border-t border-border p-5">
								{#if !editing}
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
								{:else}
									<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
										{#each [
											['primary_material', 'Material'], ['body_material', 'Body Material'], ['size', 'Size'],
											['length', 'Length'], ['length_posted', 'Length (posted)'], ['diameter', 'Diameter'],
											['weight', 'Weight'], ['cap_type', 'Cap Type'], ['nib_flex', 'Nib Flex'], ['nib_modification', 'Nib Modification'],
										] as [key, label]}
											<div>
												<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</label>
												<input type="text" bind:value={form[key]} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring" />
											</div>
										{/each}
									</div>
								{/if}
							</div>
						</div>
					</div>
				</section>
			{/if}

			<!-- Condition -->
			{#if showCondition || editing}
				<section class="overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
					<button onclick={() => showCondition = !showCondition} class="flex w-full items-center justify-between px-5 py-4 transition-colors hover:bg-secondary/30">
						<h2 class="font-serif text-base font-semibold text-foreground">Condition</h2>
						<svg class="h-5 w-5 text-muted-foreground transition-transform duration-300 {showCondition ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" /></svg>
					</button>
					<div class="section-expand" data-open={showCondition}>
						<div>
							<div class="border-t border-border p-5">
								{#if !editing}
									<div class="grid gap-x-8 gap-y-3 sm:grid-cols-2 lg:grid-cols-3">
										{#each [
											['condition_rating', 'Condition (1-10)'], ['new_used', 'New/Used'],
											['repair_required', 'Repair Required'], ['repair_cost', 'Repair Cost'], ['repaired_by', 'Repaired By'],
										] as [key, label]}
											{#if hasVal(key)}
												<div class="flex items-baseline justify-between gap-3">
													<span class="text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</span>
													<span class="text-right text-sm text-foreground">{val(key)}</span>
												</div>
											{/if}
										{/each}
									</div>
								{:else}
									<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
										<div>
											<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Condition (1-10)</label>
											<input type="number" min="1" max="10" bind:value={form.condition_rating} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring" />
										</div>
										<div>
											<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">New/Used</label>
											<select bind:value={form.new_used} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring">
												<option value="">--</option><option value="New">New</option><option value="Used">Used</option>
											</select>
										</div>
										{#each [['repair_required', 'Repair Required'], ['repaired_by', 'Repaired By']] as [key, label]}
											<div>
												<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</label>
												<input type="text" bind:value={form[key]} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring" />
											</div>
										{/each}
										<div>
											<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Repair Cost</label>
											<input type="number" step="0.01" bind:value={form.repair_cost} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring" />
										</div>
									</div>
								{/if}
							</div>
						</div>
					</div>
				</section>
			{/if}

			<!-- Purchase & Sale -->
			{#if showPurchase || editing}
				<section class="overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
					<button onclick={() => showPurchase = !showPurchase} class="flex w-full items-center justify-between px-5 py-4 transition-colors hover:bg-secondary/30">
						<h2 class="font-serif text-base font-semibold text-foreground">Purchase & Sale</h2>
						<svg class="h-5 w-5 text-muted-foreground transition-transform duration-300 {showPurchase ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" /></svg>
					</button>
					<div class="section-expand" data-open={showPurchase}>
						<div>
							<div class="border-t border-border p-5">
								{#if !editing}
									<div class="grid gap-x-8 gap-y-3 sm:grid-cols-2 lg:grid-cols-3">
										{#each [
											['purchase_price', 'Purchase Price'], ['purchase_price_currency', 'Currency'], ['purchase_date', 'Purchase Date'],
											['purchased_from', 'Purchased From'], ['shipping_cost', 'Shipping'], ['retail_price', 'Retail Price'],
											['selling_price', 'Selling Price'], ['selling_date', 'Selling Date'], ['sold_to', 'Sold To'],
											['current_value', 'Current Value'], ['valuation_date', 'Valuation Date'], ['quantity', 'Quantity'],
										] as [key, label]}
											{#if hasVal(key)}
												<div class="flex items-baseline justify-between gap-3">
													<span class="text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</span>
													<span class="text-right text-sm text-foreground">{val(key)}</span>
												</div>
											{/if}
										{/each}
									</div>
								{:else}
									<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
										{#each [
											['purchase_price', 'Purchase Price', 'number'], ['purchase_price_currency', 'Currency', 'text'], ['purchase_date', 'Purchase Date', 'date'],
											['purchased_from', 'Purchased From', 'text'], ['shipping_cost', 'Shipping', 'number'], ['retail_price', 'Retail Price', 'number'],
											['selling_price', 'Selling Price', 'number'], ['selling_date', 'Selling Date', 'date'], ['sold_to', 'Sold To', 'text'],
											['current_value', 'Current Value', 'number'], ['valuation_date', 'Valuation Date', 'date'], ['quantity', 'Quantity', 'number'],
										] as [key, label, type]}
											<div>
												<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</label>
												{#if type === 'number'}
													<input type="number" step="0.01" bind:value={form[key]} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring" />
												{:else if type === 'date'}
													<input type="date" bind:value={form[key]} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring" />
												{:else}
													<input type="text" bind:value={form[key]} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring" />
												{/if}
											</div>
										{/each}
									</div>
								{/if}
							</div>
						</div>
					</div>
				</section>
			{/if}

			<!-- Review -->
			{#if showReview || editing}
				<section class="overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
					<button onclick={() => showReview = !showReview} class="flex w-full items-center justify-between px-5 py-4 transition-colors hover:bg-secondary/30">
						<h2 class="font-serif text-base font-semibold text-foreground">Review</h2>
						<svg class="h-5 w-5 text-muted-foreground transition-transform duration-300 {showReview ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" /></svg>
					</button>
					<div class="section-expand" data-open={showReview}>
						<div>
							<div class="border-t border-border p-5 space-y-5">
								{#each [
									['first_impression', 'First Impression', 'first_impression_rating'],
									['appearance', 'Appearance', 'appearance_rating'],
									['design', 'Design', 'design_rating'],
									['nib_review', 'Nib', 'nib_rating'],
									['filling_system_review', 'Filling System', 'filling_system_rating'],
									['cost_and_value', 'Cost & Value', 'cost_and_value_rating'],
								] as [field, label, ratingField]}
									{#if !editing && (hasVal(field) || hasVal(ratingField))}
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
									{:else if editing}
										<div class="grid gap-3 sm:grid-cols-[1fr_100px]">
											<div>
												<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</label>
												<textarea bind:value={form[field]} rows="2" class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
											</div>
											<div>
												<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Rating</label>
												<input type="number" min="1" max="10" bind:value={form[ratingField]} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring" />
											</div>
										</div>
									{/if}
								{/each}
								{#if !editing && hasVal('conclusion')}
									<div>
										<h4 class="text-sm font-semibold text-foreground">Conclusion</h4>
										<p class="mt-1.5 whitespace-pre-wrap text-sm leading-relaxed text-muted-foreground">{val('conclusion')}</p>
									</div>
								{:else if editing}
									<div>
										<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Conclusion</label>
										<textarea bind:value={form.conclusion} rows="3" class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
									</div>
								{/if}
							</div>
						</div>
					</div>
				</section>
			{/if}

			<!-- Add section buttons (edit mode only) -->
			{#if editing}
				<div class="flex flex-wrap gap-2 pt-2">
					{#if !showPhysical}
						<button onclick={() => showPhysical = true} class="inline-flex items-center gap-1.5 rounded-xl border border-dashed border-border px-4 py-2.5 text-sm text-muted-foreground transition-all hover:border-primary hover:bg-primary/5 hover:text-primary">
							<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
							Physical Details
						</button>
					{/if}
					{#if !showCondition}
						<button onclick={() => showCondition = true} class="inline-flex items-center gap-1.5 rounded-xl border border-dashed border-border px-4 py-2.5 text-sm text-muted-foreground transition-all hover:border-primary hover:bg-primary/5 hover:text-primary">
							<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
							Condition
						</button>
					{/if}
					{#if !showPurchase}
						<button onclick={() => showPurchase = true} class="inline-flex items-center gap-1.5 rounded-xl border border-dashed border-border px-4 py-2.5 text-sm text-muted-foreground transition-all hover:border-primary hover:bg-primary/5 hover:text-primary">
							<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
							Purchase & Sale
						</button>
					{/if}
					{#if !showReview}
						<button onclick={() => showReview = true} class="inline-flex items-center gap-1.5 rounded-xl border border-dashed border-border px-4 py-2.5 text-sm text-muted-foreground transition-all hover:border-primary hover:bg-primary/5 hover:text-primary">
							<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
							Review
						</button>
					{/if}
				</div>

				<!-- Danger zone -->
				<div class="rounded-2xl border border-destructive/20 bg-destructive/5 p-5">
					<h3 class="mb-1 text-sm font-semibold text-destructive">Danger Zone</h3>
					<p class="mb-3 text-xs text-muted-foreground">This action cannot be undone.</p>
					<button
						onclick={handleDelete}
						disabled={deleting}
						class="inline-flex items-center gap-2 rounded-xl border border-destructive/30 px-4 py-2 text-sm font-medium text-destructive transition-colors hover:bg-destructive hover:text-destructive-foreground disabled:opacity-50"
					>
						{#if deleting}
							<div class="h-4 w-4 animate-spin rounded-full border-2 border-destructive border-t-transparent"></div>
						{/if}
						{deleting ? 'Deleting...' : 'Delete This Pen'}
					</button>
				</div>
			{/if}
		</div>
	</div>
{:else}
	<div class="flex flex-col items-center justify-center py-16 text-center">
		<svg class="mb-4 h-16 w-16 text-muted-foreground/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z" /></svg>
		<h2 class="text-lg font-medium text-foreground">Pen not found</h2>
		<p class="mt-1 text-sm text-muted-foreground">This pen may have been deleted</p>
		<a href="/app/pens" class="mt-4 rounded-xl bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">Back to Pens</a>
	</div>
{/if}
