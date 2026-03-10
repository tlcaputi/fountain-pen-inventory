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
	};

	let profile = $state<Profile>({
		first_name: '', last_name: '', email: '', phone: '',
		address1: '', address2: '', city: '', state: '', province: '',
		zip: '', country: '', fpn_username: '', preferred_currency: 'USD',
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
				updated_at: new Date().toISOString(),
			})
			.eq('id', auth.user!.id);

		if (err) error = err.message;
		else { success = 'Profile saved!'; setTimeout(() => success = '', 2000); }
		saving = false;
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
