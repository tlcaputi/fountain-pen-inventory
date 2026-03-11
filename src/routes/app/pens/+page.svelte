<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { getAuth } from '$lib/stores/auth.svelte';

	const auth = getAuth();

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

	type Collection = {
		id: string;
		name: string;
		pen_count: number;
	};

	let pens = $state<Pen[]>([]);
	let collections = $state<Collection[]>([]);
	let collectionPenIds = $state<Record<string, Set<string>>>({});
	let loading = $state(true);
	let search = $state('');
	let sortCol = $state<keyof Pen>('model');
	let sortAsc = $state(true);
	let viewMode = $state<'gallery' | 'list'>(
		(typeof window !== 'undefined' && localStorage.getItem('penViewMode') as 'gallery' | 'list') || 'list'
	);

	// Active folder: null = All Pens
	let activeFolder = $state<string | null>(null);

	// Folder sidebar state
	let showNewFolder = $state(false);
	let newFolderName = $state('');
	let creatingFolder = $state(false);
	let renamingId = $state<string | null>(null);
	let renameValue = $state('');
	let sidebarCollapsed = $state(false);

	// Drag state
	let dragPenId = $state<string | null>(null);
	let dragOverFolder = $state<string | null>(null);
	let dragFeedback = $state('');

	$effect(() => { loadAll(); });

	$effect(() => {
		if (typeof window !== 'undefined') localStorage.setItem('penViewMode', viewMode);
	});

	async function loadAll() {
		loading = true;
		const [pensRes, colsRes, cpRes] = await Promise.all([
			supabase
				.from('pens')
				.select('id, model, manufacturer, nib_stroke, color, filler, year_made, photo_closed_url, created_at')
				.order('model', { ascending: true }),
			supabase
				.from('collections')
				.select('id, name')
				.eq('user_id', auth.user!.id)
				.order('name'),
			supabase
				.from('collection_pens')
				.select('collection_id, pen_id'),
		]);

		if (pensRes.data) pens = pensRes.data;

		// Build pen ID sets per collection
		const map: Record<string, Set<string>> = {};
		if (cpRes.data) {
			for (const cp of cpRes.data) {
				if (!map[cp.collection_id]) map[cp.collection_id] = new Set();
				map[cp.collection_id].add(cp.pen_id);
			}
		}
		collectionPenIds = map;

		if (colsRes.data) {
			collections = colsRes.data.map(c => ({
				...c,
				pen_count: map[c.id]?.size ?? 0,
			}));
		}

		loading = false;
	}

	function toggleSort(col: keyof Pen) {
		if (sortCol === col) sortAsc = !sortAsc;
		else { sortCol = col; sortAsc = true; }
	}

	let filtered = $derived.by(() => {
		let list = pens;

		// Filter by active folder
		if (activeFolder) {
			const ids = collectionPenIds[activeFolder];
			if (ids) list = list.filter(p => ids.has(p.id));
			else list = [];
		}

		// Filter by search
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
	let activeFolderName = $derived(activeFolder ? collections.find(c => c.id === activeFolder)?.name ?? '' : 'All Pens');

	function sortIcon(col: keyof Pen): string {
		if (sortCol !== col) return '';
		return sortAsc ? ' \u2191' : ' \u2193';
	}

	// ── Folder CRUD ──────────────────────────────────────────────────────────

	async function createFolder() {
		if (!newFolderName.trim()) return;
		creatingFolder = true;
		const { data, error } = await supabase
			.from('collections')
			.insert({ user_id: auth.user!.id, name: newFolderName.trim() })
			.select('id, name')
			.single();
		if (!error && data) {
			collections = [...collections, { ...data, pen_count: 0 }].sort((a, b) => a.name.localeCompare(b.name));
			newFolderName = '';
			showNewFolder = false;
			activeFolder = data.id;
		}
		creatingFolder = false;
	}

	function startRename(col: Collection) {
		renamingId = col.id;
		renameValue = col.name;
	}

	async function finishRename() {
		if (!renamingId || !renameValue.trim()) { renamingId = null; return; }
		await supabase.from('collections').update({ name: renameValue.trim() }).eq('id', renamingId);
		collections = collections.map(c => c.id === renamingId ? { ...c, name: renameValue.trim() } : c)
			.sort((a, b) => a.name.localeCompare(b.name));
		renamingId = null;
	}

	async function deleteFolder(id: string, name: string) {
		if (!confirm(`Delete folder "${name}"? Pens won't be deleted, just unorganized.`)) return;
		await supabase.from('collection_pens').delete().eq('collection_id', id);
		await supabase.from('collaborators').delete().eq('collection_id', id);
		await supabase.from('collections').delete().eq('id', id);
		collections = collections.filter(c => c.id !== id);
		const { [id]: _, ...rest } = collectionPenIds;
		collectionPenIds = rest;
		if (activeFolder === id) activeFolder = null;
	}

	// ── Drag & Drop ─────────────────────────────────────────────────────────

	function onDragStart(e: DragEvent, penId: string) {
		dragPenId = penId;
		e.dataTransfer!.effectAllowed = 'copy';
		e.dataTransfer!.setData('text/plain', penId);
	}

	function onDragEnd() {
		dragPenId = null;
		dragOverFolder = null;
		dragFeedback = '';
	}

	function onFolderDragOver(e: DragEvent, folderId: string) {
		e.preventDefault();
		e.dataTransfer!.dropEffect = 'copy';
		dragOverFolder = folderId;
	}

	function onFolderDragLeave(folderId: string) {
		if (dragOverFolder === folderId) dragOverFolder = null;
	}

	async function onFolderDrop(e: DragEvent, folderId: string) {
		e.preventDefault();
		dragOverFolder = null;
		const penId = dragPenId || e.dataTransfer!.getData('text/plain');
		if (!penId) return;

		// Check if already in folder
		if (collectionPenIds[folderId]?.has(penId)) {
			const folderName = collections.find(c => c.id === folderId)?.name ?? '';
			dragFeedback = `Already in ${folderName}`;
			setTimeout(() => dragFeedback = '', 1500);
			dragPenId = null;
			return;
		}

		const { error } = await supabase
			.from('collection_pens')
			.insert({ collection_id: folderId, pen_id: penId });

		if (!error) {
			// Update local state
			const updated = { ...collectionPenIds };
			if (!updated[folderId]) updated[folderId] = new Set();
			updated[folderId] = new Set([...updated[folderId], penId]);
			collectionPenIds = updated;
			collections = collections.map(c =>
				c.id === folderId ? { ...c, pen_count: updated[folderId].size } : c
			);
			const pen = pens.find(p => p.id === penId);
			const folderName = collections.find(c => c.id === folderId)?.name ?? '';
			dragFeedback = `Added ${pen?.model ?? 'pen'} to ${folderName}`;
			setTimeout(() => dragFeedback = '', 1500);
		}
		dragPenId = null;
	}

	async function removePenFromFolder(penId: string) {
		if (!activeFolder) return;
		await supabase.from('collection_pens').delete().eq('collection_id', activeFolder).eq('pen_id', penId);
		const updated = { ...collectionPenIds };
		if (updated[activeFolder]) {
			const next = new Set(updated[activeFolder]);
			next.delete(penId);
			updated[activeFolder] = next;
			collectionPenIds = updated;
			collections = collections.map(c =>
				c.id === activeFolder ? { ...c, pen_count: next.size } : c
			);
		}
	}
</script>

<!-- Drag feedback toast -->
{#if dragFeedback}
	<div class="toast-enter fixed right-4 top-4 z-[200] flex items-center gap-2 rounded-xl bg-primary px-4 py-3 text-sm font-medium text-primary-foreground shadow-lg">
		<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" /></svg>
		{dragFeedback}
	</div>
{/if}

<div class="animate-fade-in flex gap-5">
	<!-- ── Folder sidebar (desktop) ─────────────────────────────────────── -->
	<aside class="hidden w-56 flex-shrink-0 lg:block" class:!w-0={sidebarCollapsed} class:!hidden={false}>
		{#if !sidebarCollapsed}
			<div class="sticky top-0 space-y-1">
				<div class="mb-2 flex items-center justify-between">
					<h2 class="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Folders</h2>
					<button onclick={() => sidebarCollapsed = true} class="rounded p-1 text-muted-foreground/50 hover:text-muted-foreground" title="Collapse">
						<svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" /></svg>
					</button>
				</div>

				<!-- All Pens -->
				<button
					onclick={() => activeFolder = null}
					class="flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-sm transition-colors {activeFolder === null ? 'bg-primary/10 font-medium text-primary' : 'text-muted-foreground hover:bg-secondary hover:text-foreground'}"
				>
					<svg class="h-4 w-4 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
					<span class="flex-1 truncate text-left">All Pens</span>
					<span class="text-xs tabular-nums opacity-60">{pens.length}</span>
				</button>

				<!-- Collection folders -->
				{#each collections as col}
					{#if renamingId === col.id}
						<div class="flex items-center gap-1 px-1">
							<input
								type="text"
								bind:value={renameValue}
								class="flex-1 rounded-lg border border-input bg-background px-2 py-1.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								onkeydown={(e) => { if (e.key === 'Enter') finishRename(); if (e.key === 'Escape') renamingId = null; }}
								autofocus
							/>
							<button onclick={finishRename} class="rounded p-1 text-primary hover:bg-primary/10">
								<svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" /></svg>
							</button>
						</div>
					{:else}
						<div
							class="group flex items-center rounded-xl transition-colors {activeFolder === col.id ? 'bg-primary/10' : ''} {dragOverFolder === col.id ? 'ring-2 ring-primary bg-primary/10' : ''}"
							ondragover={(e) => onFolderDragOver(e, col.id)}
							ondragleave={() => onFolderDragLeave(col.id)}
							ondrop={(e) => onFolderDrop(e, col.id)}
							role="listitem"
						>
							<button
								onclick={() => activeFolder = activeFolder === col.id ? null : col.id}
								class="flex min-w-0 flex-1 items-center gap-2.5 px-3 py-2 text-sm {activeFolder === col.id ? 'font-medium text-primary' : 'text-muted-foreground hover:text-foreground'}"
							>
								<svg class="h-4 w-4 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 0 1 4.5 9.75h15A2.25 2.25 0 0 1 21.75 12v.75m-8.69-6.44-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25h-5.379a1.5 1.5 0 0 1-1.06-.44Z" /></svg>
								<span class="flex-1 truncate text-left">{col.name}</span>
								<span class="text-xs tabular-nums opacity-60">{col.pen_count}</span>
							</button>
							<!-- Hover actions -->
							<div class="flex flex-shrink-0 items-center gap-0.5 pr-1.5 opacity-0 transition-opacity group-hover:opacity-100">
								<button onclick={() => goto(`/app/collections/${col.id}`)} class="rounded p-1 text-muted-foreground/50 hover:text-foreground" title="Settings">
									<svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z" /><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" /></svg>
								</button>
								<button onclick={() => startRename(col)} class="rounded p-1 text-muted-foreground/50 hover:text-foreground" title="Rename">
									<svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
								</button>
								<button onclick={() => deleteFolder(col.id, col.name)} class="rounded p-1 text-muted-foreground/50 hover:text-destructive" title="Delete">
									<svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" /></svg>
								</button>
							</div>
						</div>
					{/if}
				{/each}

				<!-- New folder -->
				{#if showNewFolder}
					<div class="flex items-center gap-1 px-1">
						<input
							type="text"
							bind:value={newFolderName}
							placeholder="Folder name"
							class="flex-1 rounded-lg border border-input bg-background px-2 py-1.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
							onkeydown={(e) => { if (e.key === 'Enter') createFolder(); if (e.key === 'Escape') { showNewFolder = false; newFolderName = ''; } }}
							autofocus
						/>
						<button onclick={createFolder} disabled={creatingFolder || !newFolderName.trim()} class="rounded p-1 text-primary hover:bg-primary/10 disabled:opacity-40">
							<svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" /></svg>
						</button>
					</div>
				{:else}
					<button
						onclick={() => showNewFolder = true}
						class="flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-sm text-muted-foreground/60 transition-colors hover:bg-secondary hover:text-foreground"
					>
						<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
						<span>New Folder</span>
					</button>
				{/if}

				<!-- Drag hint -->
				{#if pens.length > 0 && collections.length > 0}
					<p class="px-3 pt-2 text-[10px] text-muted-foreground/40">Drag pens onto folders</p>
				{/if}
			</div>
		{:else}
			<!-- Collapsed: just a button to expand -->
			<button onclick={() => sidebarCollapsed = false} class="sticky top-0 rounded-lg p-2 text-muted-foreground/50 hover:bg-secondary hover:text-foreground" title="Show folders">
				<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" /></svg>
			</button>
		{/if}
	</aside>

	<!-- ── Main content ─────────────────────────────────────────────────── -->
	<div class="min-w-0 flex-1 space-y-5">
		<!-- Header -->
		<div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
			<div>
				<h1 class="font-serif text-2xl font-bold text-foreground md:text-3xl">{activeFolderName}</h1>
				<p class="mt-1 text-sm text-muted-foreground">
					{filtered.length} pen{filtered.length !== 1 ? 's' : ''}
					{#if activeFolder}
						<button onclick={() => activeFolder = null} class="ml-1 text-primary hover:underline">&larr; All Pens</button>
					{/if}
				</p>
			</div>
			<button
				onclick={() => goto('/app/pens/new')}
				class="inline-flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground shadow-sm transition-all hover:bg-primary/90 hover:shadow-md active:scale-[0.98]"
			>
				<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
				Add Pen
			</button>
		</div>

		<!-- Mobile folder selector -->
		<div class="lg:hidden">
			<div class="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
				<button
					onclick={() => activeFolder = null}
					class="flex flex-shrink-0 items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition-colors {activeFolder === null ? 'border-primary bg-primary/10 text-primary' : 'border-border text-muted-foreground'}"
				>
					All Pens
					<span class="tabular-nums opacity-60">{pens.length}</span>
				</button>
				{#each collections as col}
					<button
						onclick={() => activeFolder = activeFolder === col.id ? null : col.id}
						ondragover={(e) => onFolderDragOver(e, col.id)}
						ondragleave={() => onFolderDragLeave(col.id)}
						ondrop={(e) => onFolderDrop(e, col.id)}
						class="flex flex-shrink-0 items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition-colors {activeFolder === col.id ? 'border-primary bg-primary/10 text-primary' : 'border-border text-muted-foreground'} {dragOverFolder === col.id ? 'ring-2 ring-primary' : ''}"
					>
						{col.name}
						<span class="tabular-nums opacity-60">{col.pen_count}</span>
					</button>
				{/each}
				<button
					onclick={() => { showNewFolder = true; }}
					class="flex flex-shrink-0 items-center gap-1 rounded-full border border-dashed border-border px-3 py-1.5 text-xs text-muted-foreground/60"
				>
					<svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" /></svg>
					New
				</button>
			</div>
		</div>

		<!-- Stats bar -->
		{#if pens.length > 0 && !activeFolder}
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
			{#if viewMode === 'gallery'}
				<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
					{#each Array(8) as _}
						<div class="overflow-hidden rounded-2xl border border-border bg-card">
							<div class="skeleton aspect-[3/2]"></div>
							<div class="space-y-2 p-3"><div class="skeleton h-4 w-3/4"></div><div class="skeleton h-3 w-1/2"></div></div>
						</div>
					{/each}
				</div>
			{:else}
				<div class="space-y-2">
					{#each Array(6) as _}
						<div class="flex items-center gap-3 rounded-xl border border-border bg-card p-3">
							<div class="skeleton h-16 w-16 rounded-lg"></div>
							<div class="flex-1 space-y-2"><div class="skeleton h-4 w-48"></div><div class="skeleton h-3 w-32"></div></div>
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
				{:else if activeFolder}
					<h3 class="mb-1 text-lg font-medium text-foreground">This folder is empty</h3>
					<p class="text-sm text-muted-foreground">Drag pens here to organize them</p>
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
					<div
						class="card-interactive group relative overflow-hidden rounded-2xl border border-border bg-card text-left shadow-sm {dragPenId === pen.id ? 'opacity-50' : ''}"
						draggable="true"
						ondragstart={(e) => onDragStart(e, pen.id)}
						ondragend={onDragEnd}
						role="listitem"
					>
						<button onclick={() => goto(`/app/pens/${pen.id}`)} class="block w-full text-left">
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
									{#if pen.year_made}<span class="opacity-60">{pen.manufacturer ? ' \u00b7 ' : ''}{pen.year_made}</span>{/if}
								</p>
								{#if pen.nib_stroke || pen.color}
									<p class="mt-1 truncate text-xs text-muted-foreground/70">{[pen.nib_stroke, pen.color].filter(Boolean).join(' \u00b7 ')}</p>
								{/if}
							</div>
						</button>
						{#if activeFolder}
							<button
								onclick={() => removePenFromFolder(pen.id)}
								class="absolute right-2 top-2 rounded-full bg-black/50 p-1.5 text-white opacity-0 transition-opacity group-hover:opacity-100"
								title="Remove from folder"
							>
								<svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
							</button>
						{/if}
					</div>
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
									<button onclick={() => toggleSort(col as keyof Pen)} class="transition-colors hover:text-foreground">
										{label}{sortIcon(col as keyof Pen)}
									</button>
								</th>
							{/each}
							{#if activeFolder}<th class="w-10 px-3 py-3"></th>{/if}
						</tr>
					</thead>
					<tbody class="divide-y divide-border/50">
						{#each filtered as pen}
							<tr
								class="cursor-pointer transition-colors hover:bg-secondary/30 {dragPenId === pen.id ? 'opacity-50' : ''}"
								draggable="true"
								ondragstart={(e) => onDragStart(e, pen.id)}
								ondragend={onDragEnd}
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
								{#if activeFolder}
									<td class="px-3 py-2">
										<button
											onclick={(e) => { e.stopPropagation(); removePenFromFolder(pen.id); }}
											class="rounded-lg p-1.5 text-muted-foreground/40 transition-colors hover:bg-destructive/10 hover:text-destructive"
											title="Remove from folder"
										>
											<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
										</button>
									</td>
								{/if}
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			<!-- Mobile list -->
			<div class="stagger-children space-y-2 md:hidden">
				{#each filtered as pen}
					<div
						class="card-interactive group relative flex w-full items-center gap-3 rounded-xl border border-border bg-card p-3 text-left shadow-sm {dragPenId === pen.id ? 'opacity-50' : ''}"
						draggable="true"
						ondragstart={(e) => onDragStart(e, pen.id)}
						ondragend={onDragEnd}
						role="listitem"
					>
						<button onclick={() => goto(`/app/pens/${pen.id}`)} class="flex min-w-0 flex-1 items-center gap-3">
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
									<p class="mt-0.5 truncate text-xs text-muted-foreground/70">{[pen.nib_stroke, pen.color].filter(Boolean).join(' \u00b7 ')}</p>
								{/if}
							</div>
						</button>
						{#if activeFolder}
							<button
								onclick={() => removePenFromFolder(pen.id)}
								class="flex-shrink-0 rounded-lg p-1.5 text-muted-foreground/40 transition-colors hover:text-destructive"
								title="Remove from folder"
							>
								<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
							</button>
						{/if}
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>
