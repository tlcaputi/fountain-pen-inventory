<script lang="ts">
	import PenForm from '$lib/components/PenForm.svelte';
</script>

<div class="mx-auto max-w-4xl space-y-6">
	<div class="flex items-center gap-3">
		<a href="/app/pens" class="text-muted-foreground hover:text-foreground">&larr; Back</a>
		<h1 class="font-serif text-2xl font-bold text-foreground">New Pen</h1>
	</div>
	<PenForm isNew={true} />
</div>
