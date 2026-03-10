<script lang="ts">
	import { supabase } from '$lib/supabase';

	let {
		currentUrl = '',
		onUpload,
	}: { currentUrl?: string; onUpload: (url: string) => void } = $props();

	let uploading = $state(false);
	let error = $state('');

	async function handleFile(e: Event) {
		const input = e.target as HTMLInputElement;
		const file = input.files?.[0];
		if (!file) return;

		uploading = true;
		error = '';

		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) throw new Error('Not authenticated');

			// Request presigned URL
			const res = await fetch(
				`https://dbrfpmrngreaqoggamfx.supabase.co/functions/v1/upload-url`,
				{
					method: 'POST',
					headers: {
						'Content-Type': 'application/json',
						'Authorization': `Bearer ${session.access_token}`,
					},
					body: JSON.stringify({
						filename: `${Date.now()}-${file.name}`,
						file_size_bytes: file.size,
						content_type: file.type,
					}),
				}
			);

			const result = await res.json();
			if (!res.ok) throw new Error(result.error || 'Upload failed');

			// Upload to R2
			await fetch(result.presigned_url, {
				method: 'PUT',
				body: file,
				headers: { 'Content-Type': file.type },
			});

			onUpload(result.public_url);
		} catch (err) {
			error = (err as Error).message;
		}
		uploading = false;
	}
</script>

<div>
	{#if error}
		<p class="mb-1 text-xs text-destructive">{error}</p>
	{/if}
	<label class="cursor-pointer rounded-lg border border-dashed border-border px-3 py-2 text-xs text-muted-foreground hover:border-primary hover:text-primary">
		{uploading ? 'Uploading...' : 'Upload photo'}
		<input type="file" accept="image/*" class="hidden" onchange={handleFile} disabled={uploading} />
	</label>
</div>
