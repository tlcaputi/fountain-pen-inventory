<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { getAuth } from '$lib/stores/auth.svelte';

	const auth = getAuth();

	type Collection = {
		id: string;
		name: string;
		description: string | null;
		is_public: boolean;
		share_slug: string | null;
		pen_count?: number;
	};

	let collections = $state<Collection[]>([]);
	let loading = $state(true);

	// New collection form
	let showForm = $state(false);
	let formName = $state('');
	let formDesc = $state('');
	let creating = $state(false);
	let error = $state('');

	$effect(() => { loadCollections(); });

	async function loadCollections() {
		loading = true;
		const { data } = await supabase
			.from('collections')
			.select('id, name, description, is_public, share_slug')
			.eq('user_id', auth.user!.id)
			.order('name');

		if (data) {
			// Get pen counts
			const { data: counts } = await supabase
				.from('collection_pens')
				.select('collection_id');

			const countMap: Record<string, number> = {};
			if (counts) {
				for (const c of counts) {
					countMap[c.collection_id] = (countMap[c.collection_id] || 0) + 1;
				}
			}

			collections = data.map(c => ({ ...c, pen_count: countMap[c.id] || 0 }));
		}
		loading = false;
	}

	async function createCollection() {
		if (!formName.trim()) return;
		creating = true;
		error = '';
		const { data, error: err } = await supabase
			.from('collections')
			.insert({ user_id: auth.user!.id, name: formName.trim(), description: formDesc.trim() || null })
			.select('id')
			.single();
		if (err) { error = err.message; }
		else if (data) {
			formName = '';
			formDesc = '';
			showForm = false;
			goto(`/app/collections/${data.id}`);
		}
		creating = false;
	}

	async function deleteCollection(id: string, name: string) {
		if (!confirm(`Delete "${name}"? Pens won't be deleted, just removed from this collection.`)) return;
		await supabase.from('collection_pens').delete().eq('collection_id', id);
		await supabase.from('collaborators').delete().eq('collection_id', id);
		await supabase.from('collections').delete().eq('id', id);
		collections = collections.filter(c => c.id !== id);
	}
</script>

<div class="animate-fade-in space-y-5">
	<div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
		<div>
			<h1 class="font-serif text-2xl font-bold text-foreground md:text-3xl">Collections</h1>
			<p class="mt-1 text-sm text-muted-foreground">Group your pens into collections</p>
		</div>
		<button
			onclick={() => showForm = !showForm}
			class="inline-flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground shadow-sm transition-all hover:bg-primary/90 hover:shadow-md active:scale-[0.98]"
		>
			<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
			New Collection
		</button>
	</div>

	<!-- Create form -->
	{#if showForm}
		<div class="animate-slide-down rounded-2xl border border-border bg-card p-5 shadow-sm">
			{#if error}<p class="mb-3 text-sm text-destructive">{error}</p>{/if}
			<div class="grid gap-4 sm:grid-cols-2">
				<div>
					<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Name</label>
					<input type="text" bind:value={formName} placeholder="e.g. Vintage Pens" class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
				</div>
				<div>
					<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Description</label>
					<input type="text" bind:value={formDesc} placeholder="Optional" class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
				</div>
			</div>
			<div class="mt-4 flex gap-2">
				<button onclick={createCollection} disabled={creating || !formName.trim()} class="rounded-xl bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50">
					{creating ? 'Creating...' : 'Create'}
				</button>
				<button onclick={() => { showForm = false; error = ''; }} class="rounded-xl border border-border px-4 py-2 text-sm text-muted-foreground hover:bg-secondary">Cancel</button>
			</div>
		</div>
	{/if}

	{#if loading}
		<div class="space-y-3">
			{#each Array(3) as _}
				<div class="flex items-center gap-4 rounded-2xl border border-border bg-card p-5">
					<div class="skeleton h-5 w-40"></div>
					<div class="skeleton h-4 w-20"></div>
				</div>
			{/each}
		</div>
	{:else if collections.length === 0 && !showForm}
		<div class="animate-scale-in rounded-2xl border border-dashed border-border bg-card p-16 text-center">
			<svg class="mx-auto mb-4 h-16 w-16 text-muted-foreground/40" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
				<path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 0 1 4.5 9.75h15A2.25 2.25 0 0 1 21.75 12v.75m-8.69-6.44-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25h-5.379a1.5 1.5 0 0 1-1.06-.44Z" />
			</svg>
			<h3 class="mb-1 text-lg font-medium text-foreground">No collections yet</h3>
			<p class="mb-4 text-sm text-muted-foreground">Create a collection to organize your pens</p>
		</div>
	{:else}
		<div class="stagger-children space-y-3">
			{#each collections as col}
				<div class="card-interactive flex items-center justify-between rounded-2xl border border-border bg-card p-5 shadow-sm">
					<button onclick={() => goto(`/app/collections/${col.id}`)} class="min-w-0 flex-1 text-left">
						<div class="flex items-center gap-3">
							<svg class="h-5 w-5 flex-shrink-0 text-muted-foreground" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 0 1 4.5 9.75h15A2.25 2.25 0 0 1 21.75 12v.75m-8.69-6.44-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25h-5.379a1.5 1.5 0 0 1-1.06-.44Z" /></svg>
							<div class="min-w-0">
								<h3 class="truncate font-medium text-foreground">{col.name}</h3>
								<p class="text-sm text-muted-foreground">
									{col.pen_count} pen{col.pen_count !== 1 ? 's' : ''}
									{#if col.is_public}<span class="ml-2 inline-flex items-center gap-1 rounded-full bg-success/10 px-2 py-0.5 text-xs font-medium text-success">Public</span>{/if}
								</p>
							</div>
						</div>
					</button>
					<button
						onclick={() => deleteCollection(col.id, col.name)}
						class="ml-3 flex-shrink-0 rounded-lg p-2 text-muted-foreground/50 transition-colors hover:bg-destructive/10 hover:text-destructive"
						title="Delete collection"
					>
						<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" /></svg>
					</button>
				</div>
			{/each}
		</div>
	{/if}
</div>
