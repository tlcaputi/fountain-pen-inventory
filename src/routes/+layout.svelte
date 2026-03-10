<script lang="ts">
	import '../app.css';

	let { children } = $props();

	// Initialize theme from localStorage or system preference
	if (typeof window !== 'undefined') {
		const stored = localStorage.getItem('theme');
		if (stored === 'dark' || (!stored && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
			document.documentElement.classList.add('dark');
		} else {
			document.documentElement.classList.remove('dark');
		}
	}
</script>

<svelte:head>
	<title>Fountain Pen Inventory</title>
	<meta name="description" content="Catalog, review, and manage your fountain pen collection" />
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
	<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Lora:wght@400;500;600;700&display=swap" rel="stylesheet" />
</svelte:head>

{@render children()}
