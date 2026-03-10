<script lang="ts">
	import CrudTable from '$lib/components/CrudTable.svelte';
</script>

<CrudTable
	table="ink_recipes"
	title="Ink Recipes"
	orderBy="name"
	columns={[
		{ key: 'name', label: 'Name' },
		{ key: 'color_description', label: 'Color' },
		{ key: 'recipe', label: 'Recipe' },
		{ key: 'fpn_color_category', label: 'Category' },
		{ key: 'notes', label: 'Notes' },
	]}
/>
