<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { getAuth } from '$lib/stores/auth.svelte';

	const auth = getAuth();

	type Profile = {
		first_name: string;
		last_name: string;
		email: string;
		phone: string;
		address1: string;
		address2: string;
		city: string;
		state: string;
		province: string;
		zip: string;
		country: string;
		fpn_username: string;
		preferred_currency: string;
		collection_public: boolean;
		share_slug: string;
	};

	let profile = $state<Profile>({
		first_name: '', last_name: '', email: '', phone: '',
		address1: '', address2: '', city: '', state: '', province: '',
		zip: '', country: '', fpn_username: '', preferred_currency: 'USD',
		collection_public: false, share_slug: '',
	});
	let loading = $state(true);
	let saving = $state(false);
	let error = $state('');
	let success = $state('');

	$effect(() => { loadProfile(); });

	async function loadProfile() {
		loading = true;
		const { data } = await supabase.from('profiles').select('*').single();
		if (data) {
			profile = {
				first_name: data.first_name ?? '',
				last_name: data.last_name ?? '',
				email: data.email ?? '',
				phone: data.phone ?? '',
				address1: data.address1 ?? '',
				address2: data.address2 ?? '',
				city: data.city ?? '',
				state: data.state ?? '',
				province: data.province ?? '',
				zip: data.zip ?? '',
				country: data.country ?? '',
				fpn_username: data.fpn_username ?? '',
				preferred_currency: data.preferred_currency ?? 'USD',
				collection_public: data.collection_public ?? false,
				share_slug: data.share_slug ?? '',
			};
		}
		loading = false;
	}

	async function save(e: Event) {
		e.preventDefault();
		saving = true;
		error = '';
		success = '';

		const { error: err } = await supabase
			.from('profiles')
			.update({
				first_name: profile.first_name || null,
				last_name: profile.last_name || null,
				email: profile.email || null,
				phone: profile.phone || null,
				address1: profile.address1 || null,
				address2: profile.address2 || null,
				city: profile.city || null,
				state: profile.state || null,
				province: profile.province || null,
				zip: profile.zip || null,
				country: profile.country || null,
				fpn_username: profile.fpn_username || null,
				preferred_currency: profile.preferred_currency || 'USD',
				collection_public: profile.collection_public,
				share_slug: profile.share_slug || null,
				updated_at: new Date().toISOString(),
			})
			.eq('id', auth.user!.id);

		if (err) error = err.message;
		else { success = 'Profile saved!'; setTimeout(() => success = '', 2000); }
		saving = false;
	}

	// Account-level collaborators
	type Collaborator = { id: string; collaborator_id: string; email: string };
	let collaborators = $state<Collaborator[]>([]);
	let collabEmail = $state('');
	let collabAdding = $state(false);
	let collabError = $state('');

	$effect(() => { loadCollaborators(); });

	async function loadCollaborators() {
		const { data } = await supabase
			.from('collaborators')
			.select('id, collaborator_id')
			.eq('owner_id', auth.user!.id)
			.eq('scope', 'account');

		if (data && data.length > 0) {
			const ids = data.map(c => c.collaborator_id);
			const { data: users } = await supabase.rpc('lookup_users_by_ids', { user_ids: ids });
			collaborators = data.map(c => ({
				...c,
				email: users?.find((u: { id: string }) => u.id === c.collaborator_id)?.email ?? 'Unknown'
			}));
		} else {
			collaborators = [];
		}
	}

	async function addCollaborator() {
		if (!collabEmail.trim()) return;
		collabAdding = true;
		collabError = '';
		const { data: userId, error: lookupErr } = await supabase.rpc('lookup_user_by_email', { lookup_email: collabEmail.trim() });
		if (lookupErr || !userId) {
			collabError = 'User not found. They must have a PenVault account.';
			collabAdding = false;
			return;
		}
		if (userId === auth.user!.id) {
			collabError = "You can't add yourself.";
			collabAdding = false;
			return;
		}
		const { error: insertErr } = await supabase.from('collaborators').insert({
			owner_id: auth.user!.id,
			collaborator_id: userId,
			scope: 'account',
			permission: 'edit',
		});
		if (insertErr) {
			collabError = insertErr.message.includes('duplicate') ? 'Already a collaborator.' : insertErr.message;
		} else {
			collabEmail = '';
			await loadCollaborators();
		}
		collabAdding = false;
	}

	async function removeCollaborator(id: string) {
		await supabase.from('collaborators').delete().eq('id', id);
		collaborators = collaborators.filter(c => c.id !== id);
	}

	// Storage usage
	let storageUsed = $state(0);
	$effect(() => {
		supabase.from('storage_usage').select('file_size_bytes').then(({ data }) => {
			storageUsed = data?.reduce((sum, r) => sum + (r.file_size_bytes || 0), 0) ?? 0;
		});
	});

	function formatBytes(bytes: number): string {
		if (bytes === 0) return '0 B';
		const k = 1024;
		const sizes = ['B', 'KB', 'MB', 'GB'];
		const i = Math.floor(Math.log(bytes) / Math.log(k));
		return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
	}
</script>

{#if loading}
	<div class="flex justify-center py-12"><div class="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div></div>
{:else}
	<div class="mx-auto max-w-2xl space-y-6">
		<h1 class="font-serif text-2xl font-bold text-foreground">Settings</h1>

		{#if error}<div class="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</div>{/if}
		{#if success}<div class="rounded-md bg-success/10 px-3 py-2 text-sm text-success">{success}</div>{/if}

		<form onsubmit={save} class="space-y-6">
			<section class="rounded-xl border border-border bg-card p-4 md:p-6">
				<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Personal Information</h2>
				<div class="grid gap-4 sm:grid-cols-2">
					<div>
						<label class="mb-1 block text-sm font-medium text-foreground">First Name</label>
						<input type="text" bind:value={profile.first_name} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
					</div>
					<div>
						<label class="mb-1 block text-sm font-medium text-foreground">Last Name</label>
						<input type="text" bind:value={profile.last_name} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
					</div>
					<div>
						<label class="mb-1 block text-sm font-medium text-foreground">Email</label>
						<input type="email" bind:value={profile.email} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
					</div>
					<div>
						<label class="mb-1 block text-sm font-medium text-foreground">Phone</label>
						<input type="text" bind:value={profile.phone} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
					</div>
				</div>
			</section>

			<section class="rounded-xl border border-border bg-card p-4 md:p-6">
				<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Address</h2>
				<div class="grid gap-4 sm:grid-cols-2">
					<div class="sm:col-span-2"><input type="text" bind:value={profile.address1} placeholder="Address Line 1" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" /></div>
					<div class="sm:col-span-2"><input type="text" bind:value={profile.address2} placeholder="Address Line 2" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" /></div>
					<div><input type="text" bind:value={profile.city} placeholder="City" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" /></div>
					<div><input type="text" bind:value={profile.state} placeholder="State" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" /></div>
					<div><input type="text" bind:value={profile.zip} placeholder="ZIP / Postal Code" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" /></div>
					<div><input type="text" bind:value={profile.country} placeholder="Country" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" /></div>
				</div>
			</section>

			<section class="rounded-xl border border-border bg-card p-4 md:p-6">
				<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Preferences</h2>
				<div class="grid gap-4 sm:grid-cols-2">
					<div>
						<label class="mb-1 block text-sm font-medium text-foreground">FPN Username</label>
						<input type="text" bind:value={profile.fpn_username} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
					</div>
					<div>
						<label class="mb-1 block text-sm font-medium text-foreground">Preferred Currency</label>
						<input type="text" bind:value={profile.preferred_currency} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
					</div>
				</div>
			</section>

			<section class="rounded-xl border border-border bg-card p-4 md:p-6">
				<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Public Sharing</h2>
				<p class="mb-4 text-sm text-muted-foreground">Share your entire collection publicly. Anyone with the link can view your pens (read-only, no login needed).</p>
				<div class="space-y-4">
					<div class="flex items-center justify-between">
						<label class="text-sm font-medium text-foreground">Make collection public</label>
						<button
							type="button"
							onclick={() => profile.collection_public = !profile.collection_public}
							class="relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 {profile.collection_public ? 'bg-primary' : 'bg-secondary'}"
							role="switch"
							aria-checked={profile.collection_public}
						>
							<span class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 {profile.collection_public ? 'translate-x-5' : 'translate-x-0'}"></span>
						</button>
					</div>
					<div>
						<label class="mb-1 block text-sm font-medium text-foreground">Collection URL slug</label>
						<div class="flex items-center gap-2">
							<span class="text-sm text-muted-foreground">{typeof window !== 'undefined' ? window.location.origin : ''}/c/</span>
							<input
								type="text"
								bind:value={profile.share_slug}
								placeholder="my-pens"
								pattern="[a-z0-9\-]+"
								class="flex-1 rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
							/>
						</div>
						<p class="mt-1 text-xs text-muted-foreground">Lowercase letters, numbers, and hyphens only</p>
					</div>
					{#if profile.collection_public && profile.share_slug}
						<div class="flex items-center gap-2 rounded-lg bg-success/10 px-3 py-2">
							<svg class="h-4 w-4 flex-shrink-0 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M13.19 8.688a4.5 4.5 0 0 1 1.242 7.244l-4.5 4.5a4.5 4.5 0 0 1-6.364-6.364l1.757-1.757m13.35-.622 1.757-1.757a4.5 4.5 0 0 0-6.364-6.364l-4.5 4.5a4.5 4.5 0 0 0 1.242 7.244" /></svg>
							<span class="text-sm text-success">{typeof window !== 'undefined' ? window.location.origin : ''}/c/{profile.share_slug}</span>
						</div>
					{/if}
				</div>
			</section>

			<section class="rounded-xl border border-border bg-card p-4 md:p-6">
				<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Account Collaborators</h2>
				<p class="mb-4 text-sm text-muted-foreground">Give other PenVault users edit access to <strong>all</strong> your pens. For finer control, use collection-level or pen-level sharing.</p>
				<div class="space-y-3">
					{#each collaborators as collab}
						<div class="flex items-center justify-between rounded-lg border border-border px-3 py-2">
							<span class="text-sm text-foreground">{collab.email}</span>
							<button type="button" onclick={() => removeCollaborator(collab.id)} class="text-xs text-muted-foreground hover:text-destructive">Remove</button>
						</div>
					{/each}
					<div class="flex gap-2">
						<input
							type="email"
							bind:value={collabEmail}
							placeholder="collaborator@email.com"
							class="flex-1 rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
							onkeydown={(e) => e.key === 'Enter' && (e.preventDefault(), addCollaborator())}
						/>
						<button
							type="button"
							onclick={addCollaborator}
							disabled={collabAdding || !collabEmail.trim()}
							class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
						>
							{collabAdding ? 'Adding...' : 'Add'}
						</button>
					</div>
					{#if collabError}<p class="text-sm text-destructive">{collabError}</p>{/if}
				</div>
			</section>

			<section class="rounded-xl border border-border bg-card p-4 md:p-6">
				<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Storage</h2>
				<p class="text-sm text-muted-foreground">
					Using <span class="font-medium text-foreground">{formatBytes(storageUsed)}</span> of 100 MB
				</p>
				<div class="mt-2 h-2 w-full rounded-full bg-secondary">
					<div
						class="h-2 rounded-full bg-primary transition-all"
						style="width: {Math.min(100, (storageUsed / (100 * 1024 * 1024)) * 100)}%"
					></div>
				</div>
			</section>

			<button
				type="submit"
				disabled={saving}
				class="rounded-lg bg-primary px-6 py-2.5 text-sm font-medium text-primary-foreground hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-ring disabled:opacity-50"
			>
				{saving ? 'Saving...' : 'Save Profile'}
			</button>
		</form>
	</div>
{/if}
