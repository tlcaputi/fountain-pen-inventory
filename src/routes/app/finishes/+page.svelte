<script lang="ts">
	import CrudTable from '$lib/components/CrudTable.svelte';
</script>

<CrudTable
	table="finishes"
	title="Finishes"
	orderBy="finish"
	columns={[
		{ key: 'finish', label: 'Finish' },
		{ key: 'abbreviation', label: 'Abbreviation' },
	]}
/>
