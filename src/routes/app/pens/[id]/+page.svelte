<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { page } from '$app/state';
	import { goto } from '$app/navigation';

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
	let heroIdx = $state(0);
	let lightboxOpen = $state(false);
	let lightboxIdx = $state(0);

	// Track which optional sections are expanded
	let showPhysical = $state(false);
	let showCondition = $state(false);
	let showPurchase = $state(false);
	let showReview = $state(false);

	// Editable fields
	let form = $state<Pen>({});

	$effect(() => { loadPen(); });

	async function loadPen() {
		loading = true;
		const id = page.params.id;
		const { data } = await supabase.from('pens').select('*').eq('id', id).single();
		if (data) {
			pen = data;
			form = { ...data };
			// Auto-expand sections that have data
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

	// Combine hero photo + gallery photos into one image list
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

	function val(key: string): string {
		return (pen?.[key] as string) ?? '';
	}

	function hasVal(key: string): boolean {
		const v = pen?.[key];
		return v != null && v !== '';
	}

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
			success = 'Saved!';
			pen = { ...pen, ...data };
			editing = false;
			setTimeout(() => success = '', 2000);
		}
		saving = false;
	}

	async function handleDelete() {
		if (!confirm('Delete this pen permanently?')) return;
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
</script>

<!-- Lightbox -->
{#if lightboxOpen && allImages.length > 0}
	<div
		class="fixed inset-0 z-[100] flex items-center justify-center bg-black/90"
		onclick={() => lightboxOpen = false}
		onkeydown={(e) => {
			if (e.key === 'Escape') lightboxOpen = false;
			if (e.key === 'ArrowRight') lightboxIdx = (lightboxIdx + 1) % allImages.length;
			if (e.key === 'ArrowLeft') lightboxIdx = (lightboxIdx - 1 + allImages.length) % allImages.length;
		}}
		role="dialog"
		tabindex="-1"
	>
		<button onclick={(e) => { e.stopPropagation(); lightboxIdx = (lightboxIdx - 1 + allImages.length) % allImages.length; }} class="absolute left-4 top-1/2 -translate-y-1/2 rounded-full bg-white/20 p-3 text-white hover:bg-white/40">
			<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" /></svg>
		</button>
		<img
			src={allImages[lightboxIdx].url}
			alt={allImages[lightboxIdx].caption}
			class="max-h-[90vh] max-w-[90vw] rounded-lg object-contain"
			onclick={(e) => e.stopPropagation()}
		/>
		<button onclick={(e) => { e.stopPropagation(); lightboxIdx = (lightboxIdx + 1) % allImages.length; }} class="absolute right-4 top-1/2 -translate-y-1/2 rounded-full bg-white/20 p-3 text-white hover:bg-white/40">
			<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" /></svg>
		</button>
		<button onclick={() => lightboxOpen = false} class="absolute right-4 top-4 rounded-full bg-white/20 p-2 text-white hover:bg-white/40">
			<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
		</button>
		<p class="absolute bottom-6 left-1/2 -translate-x-1/2 text-sm text-white/70">{lightboxIdx + 1} / {allImages.length}</p>
	</div>
{/if}

{#if loading}
	<div class="flex justify-center py-12">
		<div class="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
	</div>
{:else if pen}
	<div class="mx-auto max-w-6xl">
		<!-- Header -->
		<div class="mb-6 flex items-center justify-between">
			<div class="flex items-center gap-3">
				<a href="/app/pens" class="rounded-lg border border-border px-3 py-1.5 text-sm text-muted-foreground hover:bg-secondary hover:text-foreground">&larr; Back</a>
				<h1 class="font-serif text-2xl font-bold text-foreground">{val('model') || 'Untitled Pen'}</h1>
			</div>
			<div class="flex items-center gap-2">
				{#if !editing}
					<button onclick={() => { editing = true; form = { ...pen }; }} class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">Edit</button>
				{:else}
					<button onclick={handleSave} disabled={saving} class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50">{saving ? 'Saving...' : 'Save'}</button>
					<button onclick={() => { editing = false; form = { ...pen }; }} class="rounded-lg border border-border px-4 py-2 text-sm text-muted-foreground hover:bg-secondary">Cancel</button>
				{/if}
			</div>
		</div>

		{#if error}<div class="mb-4 rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</div>{/if}
		{#if success}<div class="mb-4 rounded-md bg-success/10 px-3 py-2 text-sm text-success">{success}</div>{/if}

		<!-- Two-column hero -->
		<div class="mb-6 grid gap-6 lg:grid-cols-[400px_1fr]">
			<!-- Left: Photos -->
			<div class="space-y-3">
				{#if allImages.length > 0}
					<!-- Main image -->
					<button onclick={() => openLightbox(heroIdx)} class="w-full overflow-hidden rounded-xl border border-border bg-card">
						<img
							src={allImages[heroIdx].url}
							alt={allImages[heroIdx].caption}
							class="aspect-[4/3] w-full object-cover transition-transform hover:scale-[1.02]"
						/>
					</button>
					<!-- Thumbnail strip -->
					{#if allImages.length > 1}
						<div class="flex gap-2 overflow-x-auto pb-1">
							{#each allImages as img, i}
								<button
									onclick={() => heroIdx = i}
									class="h-16 w-16 flex-shrink-0 overflow-hidden rounded-lg border-2 transition-all {heroIdx === i ? 'border-primary ring-1 ring-primary' : 'border-border opacity-70 hover:opacity-100'}"
								>
									<img src={img.url} alt={img.caption} class="h-full w-full object-cover" />
								</button>
							{/each}
						</div>
					{/if}
				{:else}
					<div class="flex aspect-[4/3] items-center justify-center rounded-xl border border-dashed border-border bg-secondary/30">
						<div class="text-center text-muted-foreground">
							<svg class="mx-auto mb-2 h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1"><path stroke-linecap="round" stroke-linejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Z" /></svg>
							<p class="text-sm">No photos yet</p>
						</div>
					</div>
				{/if}
			</div>

			<!-- Right: Key details -->
			<div class="space-y-4">
				<!-- Key facts card -->
				<div class="rounded-xl border border-border bg-card p-5">
					{#if !editing}
						<div class="space-y-3">
							{#if val('manufacturer')}
								<div class="flex items-baseline gap-2">
									<span class="text-xs font-medium uppercase tracking-wider text-muted-foreground">Maker</span>
									<span class="text-foreground">{val('manufacturer')}</span>
								</div>
							{/if}
							{#if val('year_made')}
								<div class="flex items-baseline gap-2">
									<span class="text-xs font-medium uppercase tracking-wider text-muted-foreground">Year</span>
									<span class="text-foreground">{val('year_made')}</span>
								</div>
							{/if}
							{#if val('pen_type')}
								<div class="flex items-baseline gap-2">
									<span class="text-xs font-medium uppercase tracking-wider text-muted-foreground">Type</span>
									<span class="text-foreground">{val('pen_type')}</span>
								</div>
							{/if}
							{#if val('color')}
								<div class="flex items-baseline gap-2">
									<span class="text-xs font-medium uppercase tracking-wider text-muted-foreground">Color</span>
									<span class="text-foreground">{val('color')}</span>
								</div>
							{/if}
							{#if val('filler')}
								<div class="flex items-baseline gap-2">
									<span class="text-xs font-medium uppercase tracking-wider text-muted-foreground">Filler</span>
									<span class="text-foreground">{val('filler')}</span>
								</div>
							{/if}
							{#if val('nib_stroke')}
								<div class="flex items-baseline gap-2">
									<span class="text-xs font-medium uppercase tracking-wider text-muted-foreground">Nib</span>
									<span class="text-foreground">{val('nib_stroke')}</span>
								</div>
							{/if}
							{#if val('nib_material')}
								<div class="flex items-baseline gap-2">
									<span class="text-xs font-medium uppercase tracking-wider text-muted-foreground">Nib Material</span>
									<span class="text-foreground">{val('nib_material')}</span>
								</div>
							{/if}
							{#if pen?.purchase_price != null}
								<div class="mt-4 border-t border-border pt-3">
									<span class="text-lg font-semibold text-foreground">{val('purchase_price_currency') || '$'}{pen.purchase_price}</span>
									{#if val('purchase_date')}
										<span class="ml-2 text-sm text-muted-foreground">purchased {val('purchase_date')}</span>
									{/if}
								</div>
							{/if}
						</div>
					{:else}
						<!-- Edit mode: key fields -->
						<div class="grid gap-3 sm:grid-cols-2">
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
									<label class="mb-1 block text-xs font-medium text-muted-foreground">{label}</label>
									<input type="text" bind:value={form[key]} class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
								</div>
							{/each}
						</div>
					{/if}
				</div>

				<!-- Comments -->
				{#if !editing && val('comments')}
					<div class="rounded-xl border border-border bg-card p-5">
						<h3 class="mb-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">Notes</h3>
						<p class="text-sm leading-relaxed text-foreground">{val('comments')}</p>
					</div>
				{:else if editing}
					<div class="rounded-xl border border-border bg-card p-5">
						<label class="mb-1 block text-xs font-medium text-muted-foreground">Notes</label>
						<textarea bind:value={form.comments} rows="3" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
					</div>
				{/if}

				{#if val('description')}
					<div class="rounded-xl border border-border bg-card p-5">
						<h3 class="mb-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">Description</h3>
						<p class="text-sm leading-relaxed text-foreground">{val('description')}</p>
					</div>
				{/if}
			</div>
		</div>

		<!-- Expandable sections -->
		<div class="space-y-3">
			<!-- Physical Details -->
			{#if showPhysical || editing}
				<section class="rounded-xl border border-border bg-card">
					<button onclick={() => showPhysical = !showPhysical} class="flex w-full items-center justify-between p-5">
						<h2 class="font-serif text-base font-semibold text-foreground">Physical Details</h2>
						<svg class="h-5 w-5 text-muted-foreground transition-transform {showPhysical ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" /></svg>
					</button>
					{#if showPhysical}
						<div class="border-t border-border p-5">
							{#if !editing}
								<div class="grid gap-x-8 gap-y-2 sm:grid-cols-2 lg:grid-cols-3">
									{#each [
										['primary_material', 'Material'], ['body_material', 'Body Material'], ['size', 'Size'],
										['length', 'Length'], ['length_posted', 'Length (posted)'], ['diameter', 'Diameter'],
										['weight', 'Weight'], ['cap_type', 'Cap Type'], ['nib_flex', 'Nib Flex'], ['nib_modification', 'Nib Modification'],
									] as [key, label]}
										{#if hasVal(key)}
											<div class="flex items-baseline gap-2 py-1">
												<span class="text-xs font-medium uppercase tracking-wider text-muted-foreground">{label}</span>
												<span class="text-sm text-foreground">{val(key)}</span>
											</div>
										{/if}
									{/each}
								</div>
							{:else}
								<div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
									{#each [
										['primary_material', 'Material'], ['body_material', 'Body Material'], ['size', 'Size'],
										['length', 'Length'], ['length_posted', 'Length (posted)'], ['diameter', 'Diameter'],
										['weight', 'Weight'], ['cap_type', 'Cap Type'], ['nib_flex', 'Nib Flex'], ['nib_modification', 'Nib Modification'],
									] as [key, label]}
										<div>
											<label class="mb-1 block text-xs font-medium text-muted-foreground">{label}</label>
											<input type="text" bind:value={form[key]} class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
										</div>
									{/each}
								</div>
							{/if}
						</div>
					{/if}
				</section>
			{/if}

			<!-- Condition -->
			{#if showCondition || editing}
				<section class="rounded-xl border border-border bg-card">
					<button onclick={() => showCondition = !showCondition} class="flex w-full items-center justify-between p-5">
						<h2 class="font-serif text-base font-semibold text-foreground">Condition</h2>
						<svg class="h-5 w-5 text-muted-foreground transition-transform {showCondition ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" /></svg>
					</button>
					{#if showCondition}
						<div class="border-t border-border p-5">
							{#if !editing}
								<div class="grid gap-x-8 gap-y-2 sm:grid-cols-2 lg:grid-cols-3">
									{#each [
										['condition_rating', 'Condition (1-10)'], ['new_used', 'New/Used'],
										['repair_required', 'Repair Required'], ['repair_cost', 'Repair Cost'], ['repaired_by', 'Repaired By'],
									] as [key, label]}
										{#if hasVal(key)}
											<div class="flex items-baseline gap-2 py-1">
												<span class="text-xs font-medium uppercase tracking-wider text-muted-foreground">{label}</span>
												<span class="text-sm text-foreground">{val(key)}</span>
											</div>
										{/if}
									{/each}
								</div>
							{:else}
								<div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
									<div>
										<label class="mb-1 block text-xs font-medium text-muted-foreground">Condition (1-10)</label>
										<input type="number" min="1" max="10" bind:value={form.condition_rating} class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
									</div>
									<div>
										<label class="mb-1 block text-xs font-medium text-muted-foreground">New/Used</label>
										<select bind:value={form.new_used} class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
											<option value="">--</option><option value="New">New</option><option value="Used">Used</option>
										</select>
									</div>
									{#each [['repair_required', 'Repair Required'], ['repaired_by', 'Repaired By']] as [key, label]}
										<div>
											<label class="mb-1 block text-xs font-medium text-muted-foreground">{label}</label>
											<input type="text" bind:value={form[key]} class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
										</div>
									{/each}
									<div>
										<label class="mb-1 block text-xs font-medium text-muted-foreground">Repair Cost</label>
										<input type="number" step="0.01" bind:value={form.repair_cost} class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
									</div>
								</div>
							{/if}
						</div>
					{/if}
				</section>
			{/if}

			<!-- Purchase & Sale -->
			{#if showPurchase || editing}
				<section class="rounded-xl border border-border bg-card">
					<button onclick={() => showPurchase = !showPurchase} class="flex w-full items-center justify-between p-5">
						<h2 class="font-serif text-base font-semibold text-foreground">Purchase & Sale</h2>
						<svg class="h-5 w-5 text-muted-foreground transition-transform {showPurchase ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" /></svg>
					</button>
					{#if showPurchase}
						<div class="border-t border-border p-5">
							{#if !editing}
								<div class="grid gap-x-8 gap-y-2 sm:grid-cols-2 lg:grid-cols-3">
									{#each [
										['purchase_price', 'Purchase Price'], ['purchase_price_currency', 'Currency'], ['purchase_date', 'Purchase Date'],
										['purchased_from', 'Purchased From'], ['shipping_cost', 'Shipping'], ['retail_price', 'Retail Price'],
										['selling_price', 'Selling Price'], ['selling_date', 'Selling Date'], ['sold_to', 'Sold To'],
										['current_value', 'Current Value'], ['valuation_date', 'Valuation Date'], ['quantity', 'Quantity'],
									] as [key, label]}
										{#if hasVal(key)}
											<div class="flex items-baseline gap-2 py-1">
												<span class="text-xs font-medium uppercase tracking-wider text-muted-foreground">{label}</span>
												<span class="text-sm text-foreground">{val(key)}</span>
											</div>
										{/if}
									{/each}
								</div>
							{:else}
								<div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
									{#each [
										['purchase_price', 'Purchase Price', 'number'], ['purchase_price_currency', 'Currency', 'text'], ['purchase_date', 'Purchase Date', 'date'],
										['purchased_from', 'Purchased From', 'text'], ['shipping_cost', 'Shipping', 'number'], ['retail_price', 'Retail Price', 'number'],
										['selling_price', 'Selling Price', 'number'], ['selling_date', 'Selling Date', 'date'], ['sold_to', 'Sold To', 'text'],
										['current_value', 'Current Value', 'number'], ['valuation_date', 'Valuation Date', 'date'], ['quantity', 'Quantity', 'number'],
									] as [key, label, type]}
										<div>
											<label class="mb-1 block text-xs font-medium text-muted-foreground">{label}</label>
											{#if type === 'number'}
												<input type="number" step="0.01" bind:value={form[key]} class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
											{:else if type === 'date'}
												<input type="date" bind:value={form[key]} class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
											{:else}
												<input type="text" bind:value={form[key]} class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
											{/if}
										</div>
									{/each}
								</div>
							{/if}
						</div>
					{/if}
				</section>
			{/if}

			<!-- Review -->
			{#if showReview || editing}
				<section class="rounded-xl border border-border bg-card">
					<button onclick={() => showReview = !showReview} class="flex w-full items-center justify-between p-5">
						<h2 class="font-serif text-base font-semibold text-foreground">Review</h2>
						<svg class="h-5 w-5 text-muted-foreground transition-transform {showReview ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" /></svg>
					</button>
					{#if showReview}
						<div class="border-t border-border p-5 space-y-4">
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
										<div class="flex items-baseline gap-2">
											<h4 class="text-sm font-medium text-foreground">{label}</h4>
											{#if hasVal(ratingField)}<span class="rounded-full bg-accent/20 px-2 py-0.5 text-xs font-medium text-accent">{val(ratingField)}/10</span>{/if}
										</div>
										{#if hasVal(field)}<p class="mt-1 text-sm leading-relaxed text-muted-foreground">{val(field)}</p>{/if}
									</div>
								{:else if editing}
									<div class="grid gap-3 sm:grid-cols-[1fr_80px]">
										<div>
											<label class="mb-1 block text-xs font-medium text-muted-foreground">{label}</label>
											<textarea bind:value={form[field]} rows="2" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
										</div>
										<div>
											<label class="mb-1 block text-xs font-medium text-muted-foreground">Rating</label>
											<input type="number" min="1" max="10" bind:value={form[ratingField]} class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
										</div>
									</div>
								{/if}
							{/each}
							{#if !editing && hasVal('conclusion')}
								<div>
									<h4 class="text-sm font-medium text-foreground">Conclusion</h4>
									<p class="mt-1 text-sm leading-relaxed text-muted-foreground">{val('conclusion')}</p>
								</div>
							{:else if editing}
								<div>
									<label class="mb-1 block text-xs font-medium text-muted-foreground">Conclusion</label>
									<textarea bind:value={form.conclusion} rows="3" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
								</div>
							{/if}
						</div>
					{/if}
				</section>
			{/if}

			<!-- Add section buttons (only show in edit mode for sections not yet shown) -->
			{#if editing}
				<div class="flex flex-wrap gap-2">
					{#if !showPhysical}<button onclick={() => showPhysical = true} class="rounded-lg border border-dashed border-border px-3 py-2 text-sm text-muted-foreground hover:border-primary hover:text-primary">+ Physical Details</button>{/if}
					{#if !showCondition}<button onclick={() => showCondition = true} class="rounded-lg border border-dashed border-border px-3 py-2 text-sm text-muted-foreground hover:border-primary hover:text-primary">+ Condition</button>{/if}
					{#if !showPurchase}<button onclick={() => showPurchase = true} class="rounded-lg border border-dashed border-border px-3 py-2 text-sm text-muted-foreground hover:border-primary hover:text-primary">+ Purchase & Sale</button>{/if}
					{#if !showReview}<button onclick={() => showReview = true} class="rounded-lg border border-dashed border-border px-3 py-2 text-sm text-muted-foreground hover:border-primary hover:text-primary">+ Review</button>{/if}
				</div>
			{/if}

			<!-- Delete -->
			{#if editing}
				<div class="border-t border-border pt-4">
					<button onclick={handleDelete} disabled={deleting} class="text-sm text-destructive hover:underline disabled:opacity-50">
						{deleting ? 'Deleting...' : 'Delete this pen permanently'}
					</button>
				</div>
			{/if}
		</div>
	</div>
{:else}
	<p class="text-muted-foreground">Pen not found.</p>
{/if}
