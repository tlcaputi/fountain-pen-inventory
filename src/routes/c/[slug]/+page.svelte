<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { page } from '$app/state';

	type Pen = {
		id: string;
		model: string | null;
		manufacturer: string | null;
		nib_stroke: string | null;
		color: string | null;
		year_made: string | null;
		photo_closed_url: string | null;
	};

	let title = $state('');
	let subtitle = $state('');
	let pens = $state<Pen[]>([]);
	let loading = $state(true);
	let notFound = $state(false);
	let search = $state('');

	$effect(() => { loadCollection(); });

	async function loadCollection() {
		loading = true;
		const slug = page.params.slug;

		// 1. Try named collection first
		const { data: colData } = await supabase
			.from('collections')
			.select('id, name, description, user_id')
			.eq('share_slug', slug)
			.eq('is_public', true)
			.single();

		if (colData) {
			title = colData.name;
			subtitle = colData.description ?? '';

			// Fetch pens in this collection
			const { data: cpData } = await supabase
				.from('collection_pens')
				.select('pen_id')
				.eq('collection_id', colData.id);

			if (cpData && cpData.length > 0) {
				const penIds = cpData.map(cp => cp.pen_id);
				const { data: penData } = await supabase
					.from('pens')
					.select('id, model, manufacturer, nib_stroke, color, year_made, photo_closed_url')
					.in('id', penIds)
					.order('model', { ascending: true });
				if (penData) pens = penData;
			}
			loading = false;
			return;
		}

		// 2. Fall back to profile-level slug (all pens)
		const { data: profileData } = await supabase
			.from('profiles')
			.select('id, first_name, last_name, share_slug')
			.eq('share_slug', slug)
			.eq('collection_public', true)
			.single();

		if (!profileData) {
			notFound = true;
			loading = false;
			return;
		}

		title = [profileData.first_name, profileData.last_name].filter(Boolean).join(' ') || 'Collector';
		title += "'s Collection";
		subtitle = '';

		const { data: penData } = await supabase
			.from('pens')
			.select('id, model, manufacturer, nib_stroke, color, year_made, photo_closed_url')
			.eq('user_id', profileData.id)
			.order('model', { ascending: true });

		if (penData) pens = penData;
		loading = false;
	}

	let filtered = $derived.by(() => {
		if (!search.trim()) return pens;
		const q = search.toLowerCase();
		return pens.filter(p =>
			p.model?.toLowerCase().includes(q) ||
			p.manufacturer?.toLowerCase().includes(q) ||
			p.color?.toLowerCase().includes(q) ||
			p.nib_stroke?.toLowerCase().includes(q)
		);
	});

	let uniqueMakers = $derived(new Set(pens.map(p => p.manufacturer).filter(Boolean)).size);
</script>

<svelte:head>
	<title>{title ? `${title} — PenVault` : 'PenVault'}</title>
</svelte:head>

<div class="mx-auto max-w-5xl px-4 py-8 md:px-6 lg:py-12">
	{#if loading}
		<div class="flex justify-center py-20">
			<div class="h-8 w-8 animate-spin rounded-full border-3 border-primary border-t-transparent"></div>
		</div>
	{:else if notFound}
		<div class="flex flex-col items-center justify-center py-20 text-center">
			<svg class="mb-4 h-16 w-16 text-muted-foreground/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z" /></svg>
			<h2 class="text-lg font-medium text-foreground">Collection not found</h2>
			<p class="mt-1 text-sm text-muted-foreground">This collection may not be shared publicly</p>
			<a href="/" class="mt-4 rounded-xl bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">Go to PenVault</a>
		</div>
	{:else}
		<!-- Header -->
		<div class="mb-6">
			<div class="mb-4 flex items-center gap-3">
				<a href="/" class="flex items-center gap-2 text-muted-foreground transition-colors hover:text-foreground">
					<div class="flex h-7 w-7 items-center justify-center rounded-lg bg-primary text-[10px] font-bold text-primary-foreground">PV</div>
					<span class="font-serif text-sm font-bold">PenVault</span>
				</a>
			</div>
			<h1 class="font-serif text-2xl font-bold text-foreground md:text-3xl">{title}</h1>
			<p class="mt-1 text-sm text-muted-foreground">
				{#if subtitle}{subtitle} &middot; {/if}
				{pens.length} pen{pens.length !== 1 ? 's' : ''}
				{#if uniqueMakers > 0} &middot; {uniqueMakers} maker{uniqueMakers !== 1 ? 's' : ''}{/if}
			</p>
		</div>

		<!-- Search -->
		{#if pens.length > 3}
			<div class="mb-5">
				<div class="relative">
					<svg class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" /></svg>
					<input
						type="search"
						bind:value={search}
						placeholder="Search pens..."
						class="w-full rounded-xl border border-input bg-card py-2.5 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
					/>
				</div>
			</div>
		{/if}

		<!-- Grid -->
		{#if filtered.length === 0}
			<div class="rounded-2xl border border-dashed border-border bg-card p-12 text-center">
				<p class="text-muted-foreground">{search ? `No pens match "${search}"` : 'No pens in this collection yet'}</p>
			</div>
		{:else}
			<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
				{#each filtered as pen}
					<a
						href="/p/{pen.id}"
						class="card-interactive group overflow-hidden rounded-2xl border border-border bg-card text-left shadow-sm"
					>
						{#if pen.photo_closed_url}
							<div class="overflow-hidden">
								<div class="flex aspect-[4/3] items-center justify-center bg-black">
									<img
										src={pen.photo_closed_url}
										alt={pen.model ?? 'Pen'}
										class="max-h-full max-w-full object-contain transition-transform duration-300 group-hover:scale-105"
									/>
								</div>
							</div>
						{:else}
							<div class="img-placeholder flex aspect-[4/3] items-center justify-center">
								<svg class="h-10 w-10 text-muted-foreground/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
							</div>
						{/if}
						<div class="p-3">
							<h3 class="truncate font-medium text-foreground">{pen.model ?? 'Untitled'}</h3>
							<p class="mt-0.5 truncate text-sm text-muted-foreground">
								{pen.manufacturer ?? ''}
								{#if pen.year_made}
									<span class="opacity-60">{pen.manufacturer ? ' \u00b7 ' : ''}{pen.year_made}</span>
								{/if}
							</p>
						</div>
					</a>
				{/each}
			</div>
		{/if}

		<!-- Footer -->
		<div class="mt-8 text-center">
			<a href="/" class="inline-flex items-center gap-2 text-xs text-muted-foreground/60 transition-colors hover:text-muted-foreground">
				<div class="flex h-5 w-5 items-center justify-center rounded bg-primary/80 text-[8px] font-bold text-primary-foreground">PV</div>
				Powered by PenVault
			</a>
		</div>
	{/if}
</div>
