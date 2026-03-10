<script lang="ts">
	import CrudTable from '$lib/components/CrudTable.svelte';
</script>

<CrudTable
	table="manufacturers"
	title="Manufacturers"
	orderBy="manufacturer"
	columns={[
		{ key: 'manufacturer', label: 'Manufacturer' },
		{ key: 'country', label: 'Country' },
	]}
/>
