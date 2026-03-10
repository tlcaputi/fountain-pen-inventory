<script lang="ts">
	import { supabase } from '$lib/supabase';

	type Column = { key: string; label: string; type?: 'text' | 'number' };

	let {
		table,
		columns,
		title,
		orderBy = columns[0]?.key ?? 'id',
	}: { table: string; columns: Column[]; title: string; orderBy?: string } = $props();

	let rows = $state<Record<string, unknown>[]>([]);
	let loading = $state(true);
	let search = $state('');
	let editing = $state<Record<string, unknown> | null>(null);
	let isNew = $state(false);
	let saving = $state(false);
	let error = $state('');

	$effect(() => { load(); });

	async function load() {
		loading = true;
		const { data } = await supabase
			.from(table)
			.select('*')
			.order(orderBy);
		if (data) rows = data;
		loading = false;
	}

	let filtered = $derived.by(() => {
		if (!search.trim()) return rows;
		const q = search.toLowerCase();
		return rows.filter(r =>
			columns.some(c => String(r[c.key] ?? '').toLowerCase().includes(q))
		);
	});

	function startNew() {
		isNew = true;
		const obj: Record<string, unknown> = {};
		columns.forEach(c => obj[c.key] = '');
		editing = obj;
	}

	function startEdit(row: Record<string, unknown>) {
		isNew = false;
		editing = { ...row };
	}

	async function save() {
		if (!editing) return;
		saving = true;
		error = '';

		const data: Record<string, unknown> = {};
		columns.forEach(c => {
			data[c.key] = editing![c.key] || null;
		});

		if (isNew) {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) { error = 'Not authenticated'; saving = false; return; }
			data.user_id = user.id;
			const { error: err } = await supabase.from(table).insert(data);
			if (err) error = err.message;
			else { editing = null; load(); }
		} else {
			const { error: err } = await supabase.from(table).update(data).eq('id', editing.id);
			if (err) error = err.message;
			else { editing = null; load(); }
		}
		saving = false;
	}

	async function remove(id: string) {
		if (!confirm('Delete this item?')) return;
		await supabase.from(table).delete().eq('id', id);
		load();
	}
</script>

<div class="space-y-4">
	<div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
		<h1 class="font-serif text-2xl font-bold text-foreground">
			{title} <span class="ml-2 text-base font-normal text-muted-foreground">({filtered.length})</span>
		</h1>
		<div class="flex gap-2">
			<input type="search" bind:value={search} placeholder="Search..." class="rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			<button onclick={startNew} class="whitespace-nowrap rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">+ Add</button>
		</div>
	</div>

	{#if editing}
		<div class="rounded-xl border border-border bg-card p-4 md:p-6">
			<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">{isNew ? 'Add New' : 'Edit'}</h2>
			{#if error}<p class="mb-3 text-sm text-destructive">{error}</p>{/if}
			<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
				{#each columns as col}
					<div>
						<label class="mb-1 block text-sm font-medium text-foreground">{col.label}</label>
						{#if col.type === 'number'}
							<input type="number" bind:value={editing[col.key]} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
						{:else}
							<input type="text" bind:value={editing[col.key]} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
						{/if}
					</div>
				{/each}
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
		<div class="rounded-xl border border-border bg-card p-12 text-center"><p class="text-muted-foreground">{search ? 'No matches.' : 'No items yet.'}</p></div>
	{:else}
		<div class="overflow-x-auto rounded-xl border border-border bg-card">
			<table class="w-full text-sm">
				<thead><tr class="border-b border-border bg-secondary/50">
					{#each columns as col}
						<th class="px-3 py-3 text-left font-medium text-muted-foreground">{col.label}</th>
					{/each}
					<th class="w-20 px-3 py-3"></th>
				</tr></thead>
				<tbody>
					{#each filtered as row}
						<tr class="border-b border-border/50 hover:bg-secondary/30">
							{#each columns as col, i}
								<td class="px-3 py-2 {i === 0 ? 'font-medium text-foreground' : 'text-muted-foreground'}">{row[col.key] ?? '--'}</td>
							{/each}
							<td class="px-3 py-2">
								<div class="flex gap-1">
									<button onclick={() => startEdit(row)} class="rounded p-1 text-muted-foreground hover:text-primary" title="Edit">
										<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Z" /></svg>
									</button>
									<button onclick={() => remove(row.id as string)} class="rounded p-1 text-muted-foreground hover:text-destructive" title="Delete">
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
