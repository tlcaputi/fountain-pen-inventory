<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';

	type Pen = {
		id: string;
		model: string | null;
		manufacturer: string | null;
		nib_stroke: string | null;
		color: string | null;
		filler: string | null;
		year_made: string | null;
		photo_closed_url: string | null;
		created_at: string;
	};

	let pens = $state<Pen[]>([]);
	let loading = $state(true);
	let search = $state('');
	let sortCol = $state<keyof Pen>('model');
	let sortAsc = $state(true);
	let viewMode = $state<'gallery' | 'list'>(
		(typeof window !== 'undefined' && localStorage.getItem('penViewMode') as 'gallery' | 'list') || 'list'
	);

	$effect(() => { loadPens(); });

	$effect(() => {
		if (typeof window !== 'undefined') localStorage.setItem('penViewMode', viewMode);
	});

	async function loadPens() {
		loading = true;
		const { data, error } = await supabase
			.from('pens')
			.select('id, model, manufacturer, nib_stroke, color, filler, year_made, photo_closed_url, created_at')
			.order('model', { ascending: true });
		if (!error && data) pens = data;
		loading = false;
	}

	function toggleSort(col: keyof Pen) {
		if (sortCol === col) sortAsc = !sortAsc;
		else { sortCol = col; sortAsc = true; }
	}

	let filtered = $derived.by(() => {
		let list = pens;
		if (search.trim()) {
			const q = search.toLowerCase();
			list = list.filter(p =>
				p.model?.toLowerCase().includes(q) ||
				p.manufacturer?.toLowerCase().includes(q) ||
				p.color?.toLowerCase().includes(q) ||
				p.nib_stroke?.toLowerCase().includes(q)
			);
		}
		return [...list].sort((a, b) => {
			const av = a[sortCol];
			const bv = b[sortCol];
			if (av == null && bv == null) return 0;
			if (av == null) return 1;
			if (bv == null) return -1;
			if (typeof av === 'number' && typeof bv === 'number') return sortAsc ? av - bv : bv - av;
			const cmp = String(av).localeCompare(String(bv));
			return sortAsc ? cmp : -cmp;
		});
	});

	let uniqueMakers = $derived(new Set(pens.map(p => p.manufacturer).filter(Boolean)).size);
	let uniqueNibs = $derived(new Set(pens.map(p => p.nib_stroke).filter(Boolean)).size);

	function sortIcon(col: keyof Pen): string {
		if (sortCol !== col) return '';
		return sortAsc ? ' \u2191' : ' \u2193';
	}
</script>

<div class="animate-fade-in space-y-5">
	<!-- Header -->
	<div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
		<div>
			<h1 class="font-serif text-2xl font-bold text-foreground md:text-3xl">My Pens</h1>
			<p class="mt-1 text-sm text-muted-foreground">{pens.length} pen{pens.length !== 1 ? 's' : ''} in your collection</p>
		</div>
		<button
			onclick={() => goto('/app/pens/new')}
			class="inline-flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground shadow-sm transition-all hover:bg-primary/90 hover:shadow-md active:scale-[0.98]"
		>
			<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
			Add Pen
		</button>
	</div>

	<!-- Stats bar -->
	{#if pens.length > 0}
		<div class="grid grid-cols-3 gap-3">
			<div class="rounded-xl border border-border bg-card p-3 text-center">
				<p class="text-2xl font-bold text-foreground">{pens.length}</p>
				<p class="text-xs text-muted-foreground">Pens</p>
			</div>
			<div class="rounded-xl border border-border bg-card p-3 text-center">
				<p class="text-2xl font-bold text-foreground">{uniqueMakers}</p>
				<p class="text-xs text-muted-foreground">Makers</p>
			</div>
			<div class="rounded-xl border border-border bg-card p-3 text-center">
				<p class="text-2xl font-bold text-foreground">{uniqueNibs}</p>
				<p class="text-xs text-muted-foreground">Nib Sizes</p>
			</div>
		</div>
	{/if}

	<!-- Search + View Toggle -->
	<div class="flex items-center gap-2">
		<div class="relative flex-1">
			<svg class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" /></svg>
			<input
				type="search"
				bind:value={search}
				placeholder="Search by name, maker, color..."
				class="w-full rounded-xl border border-input bg-card py-2.5 pl-10 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
			/>
		</div>
		<div class="flex rounded-xl border border-border bg-card p-1">
			<button
				onclick={() => viewMode = 'list'}
				class="rounded-lg p-2 transition-colors {viewMode === 'list' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:text-foreground'}"
				aria-label="List view"
			>
				<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.007v.008H3.75V6.75Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0ZM3.75 12h.007v.008H3.75V12Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm-.375 5.25h.007v.008H3.75v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" /></svg>
			</button>
			<button
				onclick={() => viewMode = 'gallery'}
				class="rounded-lg p-2 transition-colors {viewMode === 'gallery' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:text-foreground'}"
				aria-label="Gallery view"
			>
				<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-2.25a2.25 2.25 0 0 1-2.25-2.25v-2.25Z" /></svg>
			</button>
		</div>
	</div>

	{#if loading}
		<!-- Skeleton loading -->
		{#if viewMode === 'gallery'}
			<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
				{#each Array(8) as _}
					<div class="overflow-hidden rounded-2xl border border-border bg-card">
						<div class="skeleton aspect-[3/2]"></div>
						<div class="space-y-2 p-3">
							<div class="skeleton h-4 w-3/4"></div>
							<div class="skeleton h-3 w-1/2"></div>
						</div>
					</div>
				{/each}
			</div>
		{:else}
			<div class="space-y-2">
				{#each Array(6) as _}
					<div class="flex items-center gap-3 rounded-xl border border-border bg-card p-3">
						<div class="skeleton h-16 w-16 rounded-lg"></div>
						<div class="flex-1 space-y-2">
							<div class="skeleton h-4 w-48"></div>
							<div class="skeleton h-3 w-32"></div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	{:else if filtered.length === 0}
		<div class="animate-scale-in rounded-2xl border border-dashed border-border bg-card p-16 text-center">
			<svg class="mx-auto mb-4 h-16 w-16 text-muted-foreground/40" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
				<path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" />
			</svg>
			{#if search}
				<h3 class="mb-1 text-lg font-medium text-foreground">No pens match "{search}"</h3>
				<p class="text-sm text-muted-foreground">Try a different search term</p>
			{:else}
				<h3 class="mb-1 text-lg font-medium text-foreground">Your collection is empty</h3>
				<p class="mb-4 text-sm text-muted-foreground">Add your first fountain pen to get started</p>
				<button
					onclick={() => goto('/app/pens/new')}
					class="inline-flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground hover:bg-primary/90"
				>
					<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
					Add Your First Pen
				</button>
			{/if}
		</div>
	{:else if viewMode === 'gallery'}
		<!-- Gallery View -->
		<div class="stagger-children grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
			{#each filtered as pen}
				<button
					onclick={() => goto(`/app/pens/${pen.id}`)}
					class="card-interactive group overflow-hidden rounded-2xl border border-border bg-card text-left shadow-sm"
				>
					{#if pen.photo_closed_url}
						<div class="overflow-hidden">
							<img
								src={pen.photo_closed_url}
								alt={pen.model ?? 'Pen'}
								class="aspect-[3/2] w-full object-cover transition-transform duration-300 group-hover:scale-105"
							/>
						</div>
					{:else}
						<div class="img-placeholder flex aspect-[3/2] items-center justify-center">
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
						{#if pen.nib_stroke || pen.color}
							<p class="mt-1 truncate text-xs text-muted-foreground/70">
								{[pen.nib_stroke, pen.color].filter(Boolean).join(' \u00b7 ')}
							</p>
						{/if}
					</div>
				</button>
			{/each}
		</div>
	{:else}
		<!-- List View -->
		<!-- Desktop table -->
		<div class="hidden overflow-x-auto rounded-2xl border border-border bg-card shadow-sm md:block">
			<table class="w-full text-sm">
				<thead>
					<tr class="border-b border-border bg-secondary/40">
						<th class="w-18 px-3 py-3"></th>
						{#each [
							['model', 'Model'],
							['manufacturer', 'Maker'],
							['nib_stroke', 'Nib'],
							['color', 'Color'],
							['filler', 'Filler'],
							['year_made', 'Year'],
						] as [col, label]}
							<th class="px-3 py-3 text-left text-xs font-semibold uppercase tracking-wider text-muted-foreground">
								<button
									onclick={() => toggleSort(col as keyof Pen)}
									class="transition-colors hover:text-foreground"
								>
									{label}{sortIcon(col as keyof Pen)}
								</button>
							</th>
						{/each}
					</tr>
				</thead>
				<tbody class="divide-y divide-border/50">
					{#each filtered as pen, i}
						<tr
							class="cursor-pointer transition-colors hover:bg-secondary/30"
							onclick={() => goto(`/app/pens/${pen.id}`)}
						>
							<td class="px-3 py-2">
								{#if pen.photo_closed_url}
									<img src={pen.photo_closed_url} alt={pen.model ?? 'Pen'} class="h-14 w-14 rounded-lg object-cover" />
								{:else}
									<div class="img-placeholder flex h-14 w-14 items-center justify-center rounded-lg">
										<svg class="h-6 w-6 text-muted-foreground/40" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
									</div>
								{/if}
							</td>
							<td class="px-3 py-2 font-medium text-foreground">{pen.model ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{pen.manufacturer ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{pen.nib_stroke ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{pen.color ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{pen.filler ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{pen.year_made ?? '--'}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>

		<!-- Mobile list -->
		<div class="stagger-children space-y-2 md:hidden">
			{#each filtered as pen}
				<button
					onclick={() => goto(`/app/pens/${pen.id}`)}
					class="card-interactive flex w-full items-center gap-3 rounded-xl border border-border bg-card p-3 text-left shadow-sm"
				>
					{#if pen.photo_closed_url}
						<img src={pen.photo_closed_url} alt={pen.model ?? 'Pen'} class="h-20 w-20 flex-shrink-0 rounded-xl object-cover" />
					{:else}
						<div class="img-placeholder flex h-20 w-20 flex-shrink-0 items-center justify-center rounded-xl">
							<svg class="h-8 w-8 text-muted-foreground/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
						</div>
					{/if}
					<div class="min-w-0 flex-1">
						<p class="truncate font-medium text-foreground">{pen.model ?? 'Untitled'}</p>
						<p class="mt-0.5 text-sm text-muted-foreground">
							{pen.manufacturer ?? ''}
							{#if pen.year_made}<span class="opacity-60">{pen.manufacturer ? ' \u00b7 ' : ''}{pen.year_made}</span>{/if}
						</p>
						{#if pen.nib_stroke || pen.color}
							<p class="mt-0.5 truncate text-xs text-muted-foreground/70">
								{[pen.nib_stroke, pen.color].filter(Boolean).join(' \u00b7 ')}
							</p>
						{/if}
					</div>
				</button>
			{/each}
		</div>
	{/if}
</div>
