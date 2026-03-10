<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { page } from '$app/state';
	import PenForm from '$lib/components/PenForm.svelte';

	let pen = $state<Record<string, unknown> | null>(null);
	let photos = $state<Array<{ id: string; photo_url: string; caption: string | null; sort_order: number }>>([]);
	let loading = $state(true);

	$effect(() => {
		loadPen();
	});

	async function loadPen() {
		loading = true;
		const id = page.params.id;
		const { data } = await supabase.from('pens').select('*').eq('id', id).single();
		if (data) pen = data;

		const { data: photoData } = await supabase
			.from('pen_photos')
			.select('id, photo_url, caption, sort_order')
			.eq('pen_id', id)
			.order('sort_order');
		if (photoData) photos = photoData;

		loading = false;
	}
</script>

{#if loading}
	<div class="flex justify-center py-12">
		<div class="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
	</div>
{:else if pen}
	<div class="mx-auto max-w-4xl space-y-6">
		<div class="flex items-center gap-3">
			<a href="/app/pens" class="text-muted-foreground hover:text-foreground">&larr; Back</a>
			<h1 class="font-serif text-2xl font-bold text-foreground">{pen.model || 'Untitled Pen'}</h1>
		</div>

		<!-- Gallery -->
		{#if photos.length > 0}
			<section class="rounded-xl border border-border bg-card p-4 md:p-6">
				<h2 class="mb-3 font-serif text-lg font-semibold text-foreground">Gallery ({photos.length})</h2>
				<div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
					{#each photos as photo}
						<div class="group relative">
							<img
								src={photo.photo_url}
								alt={photo.caption ?? 'Photo'}
								class="aspect-square w-full rounded-lg object-cover"
							/>
							{#if photo.caption}
								<p class="mt-1 truncate text-xs text-muted-foreground">{photo.caption}</p>
							{/if}
						</div>
					{/each}
				</div>
			</section>
		{/if}

		<PenForm pen={pen} />
	</div>
{:else}
	<p class="text-muted-foreground">Pen not found.</p>
{/if}
