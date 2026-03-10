<script lang="ts">
	import { getAuth, signOut } from '$lib/stores/auth.svelte';
	import { getTheme } from '$lib/stores/theme.svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/state';

	const auth = getAuth();
	const theme = getTheme();
	let { children } = $props();

	let sidebarOpen = $state(false);

	// Redirect to login if not authenticated
	$effect(() => {
		if (!auth.loading && !auth.user) {
			goto('/');
		}
	});

	async function handleSignOut() {
		await signOut();
		goto('/');
	}

	const navItems = [
		{ href: '/app/pens', label: 'Pens', icon: 'pen' },
		{ href: '/app/inks', label: 'Inks', icon: 'ink' },
		{ href: '/app/recipes', label: 'Ink Recipes', icon: 'recipe' },
		{ href: '/app/manufacturers', label: 'Manufacturers', icon: 'manufacturer' },
		{ href: '/app/finishes', label: 'Finishes', icon: 'finish' },
		{ href: '/app/links', label: 'Links', icon: 'link' },
		{ href: '/app/settings', label: 'Settings', icon: 'settings' },
	];

	function isActive(href: string): boolean {
		return page.url.pathname.startsWith(href);
	}
</script>

{#if auth.loading}
	<div class="flex min-h-screen items-center justify-center bg-background">
		<div class="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
	</div>
{:else if auth.user}
	<div class="flex min-h-screen bg-background">
		<!-- Mobile sidebar overlay -->
		{#if sidebarOpen}
			<div
				class="fixed inset-0 z-40 bg-black/50 lg:hidden"
				onclick={() => sidebarOpen = false}
				onkeydown={(e) => e.key === 'Escape' && (sidebarOpen = false)}
				role="button"
				tabindex="-1"
			></div>
		{/if}

		<!-- Sidebar -->
		<aside
			class="fixed inset-y-0 left-0 z-50 flex w-64 flex-col border-r border-border bg-card transition-transform duration-200 lg:static lg:translate-x-0 {sidebarOpen ? 'translate-x-0' : '-translate-x-full'}"
		>
			<!-- Logo -->
			<div class="flex h-16 items-center gap-2 border-b border-border px-4">
				<span class="font-serif text-lg font-bold text-foreground">PenVault</span>
			</div>

			<!-- Nav -->
			<nav class="flex-1 overflow-y-auto px-3 py-4">
				<ul class="space-y-1">
					{#each navItems as item}
						<li>
							<a
								href={item.href}
								onclick={() => sidebarOpen = false}
								class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors {isActive(item.href)
									? 'bg-primary/10 text-primary'
									: 'text-muted-foreground hover:bg-secondary hover:text-foreground'}"
							>
								{#if item.icon === 'pen'}
									<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
								{:else if item.icon === 'ink'}
									<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M9.75 3.104v5.714a2.25 2.25 0 0 1-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082m.75-.082a24.301 24.301 0 0 1 4.5 0m0 0v5.714c0 .597.237 1.17.659 1.591L19 14.5M14.25 3.104c.251.023.501.05.75.082M19 14.5l-2.25 6.75H7.25L5 14.5m14 0H5" /></svg>
								{:else if item.icon === 'recipe'}
									<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.455 2.456L21.75 6l-1.036.259a3.375 3.375 0 0 0-2.455 2.456ZM16.894 20.567 16.5 21.75l-.394-1.183a2.25 2.25 0 0 0-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 0 0 1.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 0 0 1.423 1.423l1.183.394-1.183.394a2.25 2.25 0 0 0-1.423 1.423Z" /></svg>
								{:else if item.icon === 'manufacturer'}
									<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 21h16.5M4.5 3h15M5.25 3v18m13.5-18v18M9 6.75h1.5m-1.5 3h1.5m-1.5 3h1.5m3-6H15m-1.5 3H15m-1.5 3H15M9 21v-3.375c0-.621.504-1.125 1.125-1.125h3.75c.621 0 1.125.504 1.125 1.125V21" /></svg>
								{:else if item.icon === 'finish'}
									<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M9.53 16.122a3 3 0 0 0-5.78 1.128 2.25 2.25 0 0 1-2.4 2.245 4.5 4.5 0 0 0 8.4-2.245c0-.399-.078-.78-.22-1.128Zm0 0a15.998 15.998 0 0 0 3.388-1.62m-5.043-.025a15.994 15.994 0 0 1 1.622-3.395m3.42 3.42a15.995 15.995 0 0 0 4.764-4.648l3.876-5.814a1.151 1.151 0 0 0-1.597-1.597L14.146 6.32a15.996 15.996 0 0 0-4.649 4.763m3.42 3.42a6.776 6.776 0 0 0-3.42-3.42" /></svg>
								{:else if item.icon === 'link'}
									<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M13.19 8.688a4.5 4.5 0 0 1 1.242 7.244l-4.5 4.5a4.5 4.5 0 0 1-6.364-6.364l1.757-1.757m13.35-.622 1.757-1.757a4.5 4.5 0 0 0-6.364-6.364l-4.5 4.5a4.5 4.5 0 0 0 1.242 7.244" /></svg>
								{:else if item.icon === 'settings'}
									<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z" /><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" /></svg>
								{/if}
								{item.label}
							</a>
						</li>
					{/each}
				</ul>
			</nav>

			<!-- Footer -->
			<div class="border-t border-border p-4">
				<div class="flex items-center justify-between">
					<span class="truncate text-xs text-muted-foreground">{auth.user.email}</span>
					<div class="flex items-center gap-1">
						<!-- Theme toggle -->
						<button
							onclick={() => theme.toggle()}
							class="rounded-md p-1.5 text-muted-foreground hover:bg-secondary hover:text-foreground"
							title="Toggle theme"
						>
							{#if theme.dark}
								<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z" /></svg>
							{:else}
								<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z" /></svg>
							{/if}
						</button>
						<!-- Sign out -->
						<button
							onclick={handleSignOut}
							class="rounded-md p-1.5 text-muted-foreground hover:bg-secondary hover:text-foreground"
							title="Sign out"
						>
							<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6a2.25 2.25 0 0 0-2.25 2.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15m3 0 3-3m0 0-3-3m3 3H9" /></svg>
						</button>
					</div>
				</div>
			</div>
		</aside>

		<!-- Main content -->
		<div class="flex flex-1 flex-col">
			<!-- Top bar (mobile) -->
			<header class="flex h-16 items-center border-b border-border px-4 lg:hidden">
				<button
					onclick={() => sidebarOpen = !sidebarOpen}
					class="rounded-md p-2 text-muted-foreground hover:bg-secondary hover:text-foreground"
				>
					<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" /></svg>
				</button>
				<span class="ml-3 font-serif text-lg font-bold text-foreground">PenVault</span>
			</header>

			<!-- Page content -->
			<main class="flex-1 overflow-y-auto p-4 md:p-6 lg:p-8">
				{@render children()}
			</main>
		</div>
	</div>
{/if}
