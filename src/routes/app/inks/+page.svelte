<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';

	type Ink = {
		id: string;
		ink_name: string | null;
		manufacturer: string | null;
		color_description: string | null;
		fpn_color_category: string | null;
		overall_rating: number | null;
		main_photo_url: string | null;
	};

	let inks = $state<Ink[]>([]);
	let loading = $state(true);
	let search = $state('');

	$effect(() => { loadInks(); });

	async function loadInks() {
		loading = true;
		const { data } = await supabase
			.from('inks')
			.select('id, ink_name, manufacturer, color_description, fpn_color_category, overall_rating, main_photo_url')
			.order('ink_name');
		if (data) inks = data;
		loading = false;
	}

	let filtered = $derived.by(() => {
		if (!search.trim()) return inks;
		const q = search.toLowerCase();
		return inks.filter(i =>
			i.ink_name?.toLowerCase().includes(q) ||
			i.manufacturer?.toLowerCase().includes(q) ||
			i.color_description?.toLowerCase().includes(q)
		);
	});

	// Editing
	let editing = $state<Ink | null>(null);
	let form = $state<Record<string, unknown>>({});
	let saving = $state(false);
	let formError = $state('');

	function startNew() {
		editing = { id: '', ink_name: '', manufacturer: '', color_description: '', fpn_color_category: '', overall_rating: null, main_photo_url: '' };
		form = {};
	}

	function startEdit(ink: Ink) {
		editing = ink;
		form = { ...ink };
	}

	async function save() {
		saving = true;
		formError = '';
		const data: Record<string, unknown> = {
			ink_name: form.ink_name || null,
			manufacturer: form.manufacturer || null,
			color_description: form.color_description || null,
			fpn_color_category: form.fpn_color_category || null,
			overall_rating: form.overall_rating || null,
			main_photo_url: form.main_photo_url || null,
			updated_at: new Date().toISOString(),
		};

		if (!editing?.id) {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) { formError = 'Not authenticated'; saving = false; return; }
			data.user_id = user.id;
			const { error } = await supabase.from('inks').insert(data);
			if (error) formError = error.message;
			else { editing = null; loadInks(); }
		} else {
			const { error } = await supabase.from('inks').update(data).eq('id', editing.id);
			if (error) formError = error.message;
			else { editing = null; loadInks(); }
		}
		saving = false;
	}

	async function deleteInk(id: string) {
		if (!confirm('Delete this ink?')) return;
		await supabase.from('inks').delete().eq('id', id);
		loadInks();
	}
</script>

<div class="space-y-4">
	<div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
		<h1 class="font-serif text-2xl font-bold text-foreground">
			Inks <span class="ml-2 text-base font-normal text-muted-foreground">({filtered.length})</span>
		</h1>
		<div class="flex gap-2">
			<input type="search" bind:value={search} placeholder="Search inks..." class="rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			<button onclick={startNew} class="whitespace-nowrap rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">+ Add Ink</button>
		</div>
	</div>

	{#if editing}
		<div class="rounded-xl border border-border bg-card p-4 md:p-6">
			<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">{editing.id ? 'Edit Ink' : 'New Ink'}</h2>
			{#if formError}<p class="mb-3 text-sm text-destructive">{formError}</p>{/if}
			<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
				<div>
					<label class="mb-1 block text-sm font-medium text-foreground">Name</label>
					<input type="text" bind:value={form.ink_name} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
				</div>
				<div>
					<label class="mb-1 block text-sm font-medium text-foreground">Manufacturer</label>
					<input type="text" bind:value={form.manufacturer} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
				</div>
				<div>
					<label class="mb-1 block text-sm font-medium text-foreground">Color Description</label>
					<input type="text" bind:value={form.color_description} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
				</div>
				<div>
					<label class="mb-1 block text-sm font-medium text-foreground">FPN Color Category</label>
					<input type="text" bind:value={form.fpn_color_category} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
				</div>
				<div>
					<label class="mb-1 block text-sm font-medium text-foreground">Overall Rating (1-10)</label>
					<input type="number" min="1" max="10" bind:value={form.overall_rating} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
				</div>
			</div>
			<div class="mt-4 flex gap-2">
				<button onclick={save} disabled={saving} class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50">{saving ? 'Saving...' : 'Save'}</button>
				<button onclick={() => editing = null} class="rounded-lg border border-border px-4 py-2 text-sm text-muted-foreground hover:bg-secondary">Cancel</button>
			</div>
		</div>
	{/if}

	{#if loading}
		<div class="flex justify-center py-12"><div class="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div></div>
	{:else if filtered.length === 0}
		<div class="rounded-xl border border-border bg-card p-12 text-center"><p class="text-muted-foreground">{search ? 'No inks match.' : 'No inks yet.'}</p></div>
	{:else}
		<div class="overflow-x-auto rounded-xl border border-border bg-card">
			<table class="w-full text-sm">
				<thead><tr class="border-b border-border bg-secondary/50">
					<th class="px-3 py-3 text-left font-medium text-muted-foreground">Name</th>
					<th class="px-3 py-3 text-left font-medium text-muted-foreground">Maker</th>
					<th class="px-3 py-3 text-left font-medium text-muted-foreground">Color</th>
					<th class="px-3 py-3 text-left font-medium text-muted-foreground">Category</th>
					<th class="px-3 py-3 text-left font-medium text-muted-foreground">Rating</th>
					<th class="px-3 py-3 w-20"></th>
				</tr></thead>
				<tbody>
					{#each filtered as ink}
						<tr class="border-b border-border/50 hover:bg-secondary/30">
							<td class="px-3 py-2 font-medium text-foreground">{ink.ink_name ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{ink.manufacturer ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{ink.color_description ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{ink.fpn_color_category ?? '--'}</td>
							<td class="px-3 py-2 text-muted-foreground">{ink.overall_rating ?? '--'}</td>
							<td class="px-3 py-2">
								<div class="flex gap-1">
									<button onclick={() => startEdit(ink)} class="rounded p-1 text-muted-foreground hover:text-primary" title="Edit">
										<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Z" /></svg>
									</button>
									<button onclick={() => deleteInk(ink.id)} class="rounded p-1 text-muted-foreground hover:text-destructive" title="Delete">
										<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" /></svg>
									</button>
								</div>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</div>
