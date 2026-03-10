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
		purchase_price: number | null;
		purchase_price_currency: string | null;
		photo_closed_url: string | null;
		created_at: string;
	};

	let pens = $state<Pen[]>([]);
	let loading = $state(true);
	let search = $state('');
	let sortCol = $state<keyof Pen>('model');
	let sortAsc = $state(true);

	$effect(() => {
		loadPens();
	});

	async function loadPens() {
		loading = true;
		const { data, error } = await supabase
			.from('pens')
			.select('id, model, manufacturer, nib_stroke, color, filler, year_made, purchase_price, purchase_price_currency, photo_closed_url, created_at')
			.order('model', { ascending: true });
		if (!error && data) {
			pens = data;
		}
		loading = false;
	}

	function toggleSort(col: keyof Pen) {
		if (sortCol === col) {
			sortAsc = !sortAsc;
		} else {
			sortCol = col;
			sortAsc = true;
		}
	}

	let filtered = $derived.by(() => {
		let list = pens;
		if (search.trim()) {
			const q = search.toLowerCase();
			list = list.filter(p =>
				(p.model?.toLowerCase().includes(q)) ||
				(p.manufacturer?.toLowerCase().includes(q)) ||
				(p.color?.toLowerCase().includes(q)) ||
				(p.nib_stroke?.toLowerCase().includes(q))
			);
		}
		list = [...list].sort((a, b) => {
			const av = a[sortCol];
			const bv = b[sortCol];
			if (av == null && bv == null) return 0;
			if (av == null) return 1;
			if (bv == null) return -1;
			if (typeof av === 'number' && typeof bv === 'number') {
				return sortAsc ? av - bv : bv - av;
			}
			const cmp = String(av).localeCompare(String(bv));
			return sortAsc ? cmp : -cmp;
		});
		return list;
	});

	function sortIcon(col: keyof Pen): string {
		if (sortCol !== col) return '';
		return sortAsc ? ' \u2191' : ' \u2193';
	}
</script>

<div class="space-y-4">
	<!-- Header -->
	<div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
		<h1 class="font-serif text-2xl font-bold text-foreground">
			Pens
			<span class="ml-2 text-base font-normal text-muted-foreground">({filtered.length})</span>
		</h1>
		<div class="flex gap-2">
			<input
				type="search"
				bind:value={search}
				placeholder="Search pens..."
				class="rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
			/>
			<button
				onclick={() => goto('/app/pens/new')}
				class="whitespace-nowrap rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-ring"
			>
				+ Add Pen
			</button>
		</div>
	</div>

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
		</div>
	{:else if filtered.length === 0}
		<div class="rounded-xl border border-border bg-card p-12 text-center">
			<p class="text-muted-foreground">
				{search ? 'No pens match your search.' : 'No pens yet. Add your first pen!'}
			</p>
		</div>
	{:else}
		<!-- Table (desktop) -->
		<div class="hidden overflow-x-auto rounded-xl border border-border bg-card md:block">
			<table class="w-full text-sm">
				<thead>
					<tr class="border-b border-border bg-secondary/50">
						<th class="w-12 px-3 py-3"></th>
						{#each [
							['model', 'Model'],
							['manufacturer', 'Maker'],
							['nib_stroke', 'Nib'],
							['color', 'Color'],
							['filler', 'Filler'],
							['year_made', 'Year'],
							['purchase_price', 'Price'],
						] as [col, label]}
							<th class="px-3 py-3 text-left font-medium text-muted-foreground">
								<button
									onclick={() => toggleSort(col as keyof Pen)}
									class="hover:text-foreground"
								>
									{label}{sortIcon(col as keyof Pen)}
								</button>
							</th>
						{/each}
					</tr>
				</thead>
				<tbody>
					{#each filtered as pen}
						<tr
							class="cursor-pointer border-b border-border/50 transition-colors hover:bg-secondary/30"
							onclick={() => goto(`/app/pens/${pen.id}`)}
						>
							<td class="px-3 py-2">
								{#if pen.photo_closed_url}
									<img
										src={pen.photo_closed_url}
										alt={pen.model ?? 'Pen'}
										class="h-10 w-10 rounded-md object-cover"
									/>
								{:else}
									<div class="flex h-10 w-10 items-center justify-center rounded-md bg-secondary text-muted-foreground">
										<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
									</div>
								{/if}
							</td>
							<td class="px-3 py-2 font-medium text-foreground">{pen.model ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{pen.manufacturer ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{pen.nib_stroke ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{pen.color ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{pen.filler ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{pen.year_made ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">
								{pen.purchase_price != null ? `${pen.purchase_price_currency ?? '$'}${pen.purchase_price}` : '--'}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>

		<!-- Cards (mobile) -->
		<div class="space-y-3 md:hidden">
			{#each filtered as pen}
				<button
					onclick={() => goto(`/app/pens/${pen.id}`)}
					class="flex w-full items-center gap-3 rounded-xl border border-border bg-card p-3 text-left transition-colors hover:bg-secondary/30"
				>
					{#if pen.photo_closed_url}
						<img
							src={pen.photo_closed_url}
							alt={pen.model ?? 'Pen'}
							class="h-14 w-14 flex-shrink-0 rounded-lg object-cover"
						/>
					{:else}
						<div class="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-lg bg-secondary text-muted-foreground">
							<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
						</div>
					{/if}
					<div class="min-w-0 flex-1">
						<p class="truncate font-medium text-foreground">{pen.model ?? 'Untitled'}</p>
						<p class="text-xs text-muted-foreground">{pen.manufacturer ?? ''} {pen.year_made ? `(${pen.year_made})` : ''}</p>
						{#if pen.nib_stroke || pen.color}
							<p class="text-xs text-muted-foreground">{[pen.nib_stroke, pen.color].filter(Boolean).join(' / ')}</p>
						{/if}
					</div>
				</button>
			{/each}
		</div>
	{/if}
</div>
