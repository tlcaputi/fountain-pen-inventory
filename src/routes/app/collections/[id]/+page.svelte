<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { page } from '$app/state';
	import { goto } from '$app/navigation';
	import { getAuth } from '$lib/stores/auth.svelte';

	const auth = getAuth();

	type Collection = { id: string; user_id: string; name: string; description: string | null; is_public: boolean; share_slug: string | null };
	type Pen = { id: string; model: string | null; manufacturer: string | null; nib_stroke: string | null; color: string | null; year_made: string | null; photo_closed_url: string | null };
	type Collaborator = { id: string; collaborator_id: string; email: string | null; scope: string; permission: string };

	let collection = $state<Collection | null>(null);
	let pensInCollection = $state<Pen[]>([]);
	let allPens = $state<Pen[]>([]);
	let collaborators = $state<Collaborator[]>([]);
	let loading = $state(true);
	let saving = $state(false);
	let error = $state('');
	let success = $state('');

	// Editing
	let editName = $state('');
	let editDesc = $state('');
	let editPublic = $state(false);
	let editSlug = $state('');

	// Add pens picker
	let showPicker = $state(false);
	let pickerSearch = $state('');

	// Add collaborator
	let collabEmail = $state('');
	let addingCollab = $state(false);

	// Share link
	let shareCopied = $state(false);

	let isOwner = $derived(collection?.user_id === auth.user?.id);

	$effect(() => { loadCollection(); });

	async function loadCollection() {
		loading = true;
		const id = page.params.id;

		const { data } = await supabase.from('collections').select('*').eq('id', id).single();
		if (!data) { loading = false; return; }
		collection = data;
		editName = data.name;
		editDesc = data.description ?? '';
		editPublic = data.is_public;
		editSlug = data.share_slug ?? '';

		// Load pens in this collection
		const { data: cpData } = await supabase.from('collection_pens').select('pen_id').eq('collection_id', id);
		if (cpData && cpData.length > 0) {
			const penIds = cpData.map(cp => cp.pen_id);
			const { data: penData } = await supabase
				.from('pens')
				.select('id, model, manufacturer, nib_stroke, color, year_made, photo_closed_url')
				.in('id', penIds)
				.order('model');
			if (penData) pensInCollection = penData;
		}

		// Load all user's pens for the picker
		if (data.user_id === auth.user?.id) {
			const { data: allData } = await supabase
				.from('pens')
				.select('id, model, manufacturer, nib_stroke, color, year_made, photo_closed_url')
				.eq('user_id', auth.user!.id)
				.order('model');
			if (allData) allPens = allData;
		}

		// Load collaborators
		const { data: collabData } = await supabase
			.from('collaborators')
			.select('id, collaborator_id, scope, permission')
			.eq('scope', 'collection')
			.eq('collection_id', id);
		if (collabData) {
			// Look up emails from profiles
			const ids = collabData.map(c => c.collaborator_id);
			if (ids.length > 0) {
				const { data: profiles } = await supabase.from('profiles').select('id, email').in('id', ids);
				const emailMap: Record<string, string> = {};
				if (profiles) for (const p of profiles) emailMap[p.id] = p.email ?? '';
				collaborators = collabData.map(c => ({ ...c, email: emailMap[c.collaborator_id] ?? 'Unknown' }));
			}
		}

		loading = false;
	}

	async function saveSettings() {
		if (!collection || !isOwner) return;
		saving = true;
		error = '';
		const { error: err } = await supabase.from('collections').update({
			name: editName.trim(),
			description: editDesc.trim() || null,
			is_public: editPublic,
			share_slug: editSlug.trim() || null,
			updated_at: new Date().toISOString(),
		}).eq('id', collection.id);
		if (err) error = err.message;
		else {
			collection = { ...collection, name: editName.trim(), description: editDesc.trim() || null, is_public: editPublic, share_slug: editSlug.trim() || null };
			success = 'Saved';
			setTimeout(() => success = '', 2000);
		}
		saving = false;
	}

	let availablePens = $derived.by(() => {
		const inIds = new Set(pensInCollection.map(p => p.id));
		let list = allPens.filter(p => !inIds.has(p.id));
		if (pickerSearch.trim()) {
			const q = pickerSearch.toLowerCase();
			list = list.filter(p => p.model?.toLowerCase().includes(q) || p.manufacturer?.toLowerCase().includes(q));
		}
		return list;
	});

	async function addPen(penId: string) {
		if (!collection) return;
		const { error: err } = await supabase.from('collection_pens').insert({ collection_id: collection.id, pen_id: penId });
		if (!err) {
			const pen = allPens.find(p => p.id === penId);
			if (pen) pensInCollection = [...pensInCollection, pen].sort((a, b) => (a.model ?? '').localeCompare(b.model ?? ''));
		}
	}

	async function removePen(penId: string) {
		if (!collection) return;
		await supabase.from('collection_pens').delete().eq('collection_id', collection.id).eq('pen_id', penId);
		pensInCollection = pensInCollection.filter(p => p.id !== penId);
	}

	async function addCollaborator() {
		if (!collection || !collabEmail.trim()) return;
		addingCollab = true;
		error = '';

		const { data: userId } = await supabase.rpc('lookup_user_by_email', { lookup_email: collabEmail.trim() });
		if (!userId) { error = 'No PenVault user found with that email'; addingCollab = false; return; }
		if (userId === auth.user?.id) { error = 'You cannot add yourself'; addingCollab = false; return; }

		const { error: err } = await supabase.from('collaborators').insert({
			owner_id: auth.user!.id,
			collaborator_id: userId,
			scope: 'collection',
			collection_id: collection.id,
			permission: 'edit',
		});
		if (err) {
			error = err.message.includes('duplicate') ? 'This user already has access' : err.message;
		} else {
			collaborators = [...collaborators, { id: crypto.randomUUID(), collaborator_id: userId, email: collabEmail.trim(), scope: 'collection', permission: 'edit' }];
			collabEmail = '';
			success = 'Collaborator added';
			setTimeout(() => success = '', 2000);
		}
		addingCollab = false;
	}

	async function removeCollaborator(id: string) {
		await supabase.from('collaborators').delete().eq('id', id);
		collaborators = collaborators.filter(c => c.id !== id);
	}

	async function copyShareLink() {
		if (!collection?.share_slug) return;
		await navigator.clipboard.writeText(`${window.location.origin}/c/${collection.share_slug}`);
		shareCopied = true;
		setTimeout(() => shareCopied = false, 2000);
	}
</script>

{#if success}
	<div class="toast-enter fixed right-4 top-4 z-[200] flex items-center gap-2 rounded-xl bg-success px-4 py-3 text-sm font-medium text-white shadow-lg">
		<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" /></svg>
		{success}
	</div>
{/if}

{#if loading}
	<div class="flex justify-center py-12"><div class="h-8 w-8 animate-spin rounded-full border-3 border-primary border-t-transparent"></div></div>
{:else if !collection}
	<div class="text-center py-16">
		<h2 class="text-lg font-medium text-foreground">Collection not found</h2>
		<a href="/app/collections" class="mt-4 inline-block rounded-xl bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">Back to Collections</a>
	</div>
{:else}
	<div class="mx-auto max-w-5xl animate-slide-up space-y-6">
		<!-- Header -->
		<div class="flex items-center justify-between gap-4">
			<div class="flex items-center gap-3">
				<a href="/app/collections" class="group flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-sm text-muted-foreground transition-all hover:border-primary hover:bg-primary/5 hover:text-primary">
					<svg class="h-4 w-4 transition-transform group-hover:-translate-x-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" /></svg>
					Back
				</a>
				<h1 class="font-serif text-xl font-bold text-foreground md:text-2xl">{collection.name}</h1>
				{#if collection.is_public}<span class="rounded-full bg-success/10 px-2.5 py-0.5 text-xs font-medium text-success">Public</span>{/if}
			</div>
			{#if isOwner && collection.is_public && collection.share_slug}
				<button onclick={copyShareLink} class="inline-flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-sm transition-colors {shareCopied ? 'border-success/30 bg-success/10 text-success' : 'text-muted-foreground hover:bg-secondary hover:text-foreground'}">
					{#if shareCopied}
						<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" /></svg>
						Copied!
					{:else}
						<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M13.19 8.688a4.5 4.5 0 0 1 1.242 7.244l-4.5 4.5a4.5 4.5 0 0 1-6.364-6.364l1.757-1.757m13.35-.622 1.757-1.757a4.5 4.5 0 0 0-6.364-6.364l-4.5 4.5a4.5 4.5 0 0 0 1.242 7.244" /></svg>
						Copy Link
					{/if}
				</button>
			{/if}
		</div>

		{#if collection.description}
			<p class="text-sm text-muted-foreground">{collection.description}</p>
		{/if}

		<!-- Pens in collection -->
		<section>
			<div class="mb-3 flex items-center justify-between">
				<h2 class="font-serif text-base font-semibold text-foreground">{pensInCollection.length} Pen{pensInCollection.length !== 1 ? 's' : ''}</h2>
				{#if isOwner}
					<button onclick={() => showPicker = !showPicker} class="inline-flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-sm text-muted-foreground transition-colors hover:bg-secondary hover:text-foreground">
						<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
						Add Pens
					</button>
				{/if}
			</div>

			<!-- Pen picker -->
			{#if showPicker && isOwner}
				<div class="mb-4 animate-slide-down rounded-2xl border border-border bg-card p-4 shadow-sm">
					<input type="search" bind:value={pickerSearch} placeholder="Search your pens..." class="mb-3 w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
					{#if availablePens.length === 0}
						<p class="py-4 text-center text-sm text-muted-foreground">{pickerSearch ? 'No matches' : 'All pens are in this collection'}</p>
					{:else}
						<div class="max-h-64 space-y-1 overflow-y-auto">
							{#each availablePens as pen}
								<button onclick={() => addPen(pen.id)} class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left transition-colors hover:bg-secondary">
									{#if pen.photo_closed_url}
										<img src={pen.photo_closed_url} alt="" class="h-10 w-10 rounded-lg object-cover" />
									{:else}
										<div class="img-placeholder flex h-10 w-10 items-center justify-center rounded-lg"><svg class="h-5 w-5 text-muted-foreground/40" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg></div>
									{/if}
									<div class="min-w-0 flex-1">
										<p class="truncate text-sm font-medium text-foreground">{pen.model ?? 'Untitled'}</p>
										<p class="truncate text-xs text-muted-foreground">{pen.manufacturer ?? ''}</p>
									</div>
									<svg class="h-4 w-4 flex-shrink-0 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
								</button>
							{/each}
						</div>
					{/if}
				</div>
			{/if}

			<!-- Pen grid -->
			{#if pensInCollection.length === 0}
				<div class="rounded-2xl border border-dashed border-border bg-card p-12 text-center">
					<p class="text-sm text-muted-foreground">No pens in this collection yet</p>
				</div>
			{:else}
				<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
					{#each pensInCollection as pen}
						<div class="group relative overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
							<a href="/app/pens/{pen.id}" class="block">
								{#if pen.photo_closed_url}
									<div class="flex aspect-[4/3] items-center justify-center bg-black">
										<img src={pen.photo_closed_url} alt={pen.model ?? 'Pen'} class="max-h-full max-w-full object-contain" />
									</div>
								{:else}
									<div class="img-placeholder flex aspect-[4/3] items-center justify-center">
										<svg class="h-10 w-10 text-muted-foreground/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
									</div>
								{/if}
								<div class="p-3">
									<h3 class="truncate font-medium text-foreground">{pen.model ?? 'Untitled'}</h3>
									<p class="mt-0.5 truncate text-sm text-muted-foreground">{pen.manufacturer ?? ''}</p>
								</div>
							</a>
							{#if isOwner}
								<button
									onclick={() => removePen(pen.id)}
									class="absolute right-2 top-2 rounded-full bg-black/50 p-1.5 text-white opacity-0 transition-opacity group-hover:opacity-100"
									title="Remove from collection"
								>
									<svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
								</button>
							{/if}
						</div>
					{/each}
				</div>
			{/if}
		</section>

		{#if isOwner}
			<!-- Settings -->
			<section class="rounded-2xl border border-border bg-card p-5 shadow-sm">
				<h2 class="mb-4 font-serif text-base font-semibold text-foreground">Collection Settings</h2>
				{#if error}<p class="mb-3 text-sm text-destructive">{error}</p>{/if}
				<div class="grid gap-4 sm:grid-cols-2">
					<div>
						<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Name</label>
						<input type="text" bind:value={editName} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
					</div>
					<div>
						<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Description</label>
						<input type="text" bind:value={editDesc} class="w-full rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
					</div>
				</div>
				<div class="mt-4 flex items-center justify-between">
					<label class="text-sm font-medium text-foreground">Public</label>
					<button type="button" onclick={() => editPublic = !editPublic} class="relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 {editPublic ? 'bg-primary' : 'bg-secondary'}" role="switch" aria-checked={editPublic}>
						<span class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 {editPublic ? 'translate-x-5' : 'translate-x-0'}"></span>
					</button>
				</div>
				{#if editPublic}
					<div class="mt-3">
						<label class="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Share Slug</label>
						<div class="flex items-center gap-2">
							<span class="text-sm text-muted-foreground">/c/</span>
							<input type="text" bind:value={editSlug} placeholder="my-vintage-pens" class="flex-1 rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
						</div>
					</div>
				{/if}
				<button onclick={saveSettings} disabled={saving} class="mt-4 rounded-xl bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50">
					{saving ? 'Saving...' : 'Save Settings'}
				</button>
			</section>

			<!-- Collaborators -->
			<section class="rounded-2xl border border-border bg-card p-5 shadow-sm">
				<h2 class="mb-4 font-serif text-base font-semibold text-foreground">Collaborators</h2>
				<p class="mb-4 text-sm text-muted-foreground">Grant edit access to other PenVault users for pens in this collection.</p>

				<div class="flex gap-2">
					<input type="email" bind:value={collabEmail} placeholder="user@example.com" class="flex-1 rounded-xl border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
					<button onclick={addCollaborator} disabled={addingCollab || !collabEmail.trim()} class="rounded-xl bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50">
						{addingCollab ? 'Adding...' : 'Add'}
					</button>
				</div>

				{#if collaborators.length > 0}
					<div class="mt-4 space-y-2">
						{#each collaborators as collab}
							<div class="flex items-center justify-between rounded-xl border border-border px-4 py-2.5">
								<div>
									<p class="text-sm font-medium text-foreground">{collab.email}</p>
									<p class="text-xs text-muted-foreground">Can edit</p>
								</div>
								<button onclick={() => removeCollaborator(collab.id)} class="rounded-lg p-1.5 text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive" title="Remove">
									<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
								</button>
							</div>
						{/each}
					</div>
				{/if}
			</section>
		{/if}
	</div>
{/if}
