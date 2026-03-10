<script lang="ts">
	import CrudTable from '$lib/components/CrudTable.svelte';
</script>

<CrudTable
	table="links"
	title="Links"
	orderBy="name"
	columns={[
		{ key: 'name', label: 'Name' },
		{ key: 'url', label: 'URL' },
		{ key: 'description', label: 'Description' },
		{ key: 'type', label: 'Type' },
	]}
/>
