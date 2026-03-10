<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import PhotoUploader from './PhotoUploader.svelte';

	type PenData = Record<string, unknown>;

	let {
		pen = {} as PenData,
		isNew = false,
	}: { pen?: PenData; isNew?: boolean } = $props();

	let saving = $state(false);
	let deleting = $state(false);
	let error = $state('');
	let success = $state('');

	// Form fields organized by section
	let model = $state((pen.model as string) ?? '');
	let manufacturer = $state((pen.manufacturer as string) ?? '');
	let description = $state((pen.description as string) ?? '');
	let pen_type = $state((pen.pen_type as string) ?? '');
	let year_made = $state((pen.year_made as string) ?? '');
	let color = $state((pen.color as string) ?? '');
	let primary_material = $state((pen.primary_material as string) ?? '');
	let body_material = $state((pen.body_material as string) ?? '');
	let size = $state((pen.size as string) ?? '');
	let length_val = $state((pen.length as string) ?? '');
	let length_posted = $state((pen.length_posted as string) ?? '');
	let diameter = $state((pen.diameter as string) ?? '');
	let weight = $state((pen.weight as string) ?? '');
	let cap_type = $state((pen.cap_type as string) ?? '');
	let nib_stroke = $state((pen.nib_stroke as string) ?? '');
	let nib_material = $state((pen.nib_material as string) ?? '');
	let nib_flex = $state((pen.nib_flex as string) ?? '');
	let nib_modification = $state((pen.nib_modification as string) ?? '');
	let filler = $state((pen.filler as string) ?? '');
	let condition_rating = $state((pen.condition_rating as number) ?? null);
	let new_used = $state((pen.new_used as string) ?? '');
	let repair_required = $state((pen.repair_required as string) ?? '');
	let repair_cost = $state((pen.repair_cost as number) ?? null);
	let repaired_by = $state((pen.repaired_by as string) ?? '');
	let comments = $state((pen.comments as string) ?? '');
	let miscellaneous = $state((pen.miscellaneous as string) ?? '');
	let purchase_price = $state((pen.purchase_price as number) ?? null);
	let purchase_price_currency = $state((pen.purchase_price_currency as string) ?? 'USD');
	let purchase_date = $state((pen.purchase_date as string) ?? '');
	let purchased_from = $state((pen.purchased_from as string) ?? '');
	let shipping_cost = $state((pen.shipping_cost as number) ?? null);
	let retail_price = $state((pen.retail_price as number) ?? null);
	let selling_price = $state((pen.selling_price as number) ?? null);
	let selling_date = $state((pen.selling_date as string) ?? '');
	let sold_to = $state((pen.sold_to as string) ?? '');
	let current_value = $state((pen.current_value as number) ?? null);
	let valuation_date = $state((pen.valuation_date as string) ?? '');
	let quantity = $state((pen.quantity as number) ?? 1);
	let photo_closed_url = $state((pen.photo_closed_url as string) ?? '');
	let photo_open_url = $state((pen.photo_open_url as string) ?? '');
	let photo_posted_url = $state((pen.photo_posted_url as string) ?? '');
	let photo_nib_url = $state((pen.photo_nib_url as string) ?? '');
	let photo_converter_url = $state((pen.photo_converter_url as string) ?? '');
	let photo_closed_caption = $state((pen.photo_closed_caption as string) ?? '');
	let photo_open_caption = $state((pen.photo_open_caption as string) ?? '');
	let photo_posted_caption = $state((pen.photo_posted_caption as string) ?? '');
	let photo_nib_caption = $state((pen.photo_nib_caption as string) ?? '');
	let photo_converter_caption = $state((pen.photo_converter_caption as string) ?? '');

	// Reviews
	let first_impression = $state((pen.first_impression as string) ?? '');
	let appearance = $state((pen.appearance as string) ?? '');
	let design = $state((pen.design as string) ?? '');
	let nib_review = $state((pen.nib_review as string) ?? '');
	let filling_system_review = $state((pen.filling_system_review as string) ?? '');
	let cost_and_value = $state((pen.cost_and_value as string) ?? '');
	let conclusion = $state((pen.conclusion as string) ?? '');

	// Ratings
	let first_impression_rating = $state((pen.first_impression_rating as number) ?? null);
	let appearance_rating = $state((pen.appearance_rating as number) ?? null);
	let design_rating = $state((pen.design_rating as number) ?? null);
	let nib_rating = $state((pen.nib_rating as number) ?? null);
	let filling_system_rating = $state((pen.filling_system_rating as number) ?? null);
	let cost_and_value_rating = $state((pen.cost_and_value_rating as number) ?? null);

	async function handleSave(e: Event) {
		e.preventDefault();
		saving = true;
		error = '';
		success = '';

		const data: Record<string, unknown> = {
			model: model || null,
			manufacturer: manufacturer || null,
			description: description || null,
			pen_type: pen_type || null,
			year_made: year_made || null,
			color: color || null,
			primary_material: primary_material || null,
			body_material: body_material || null,
			size: size || null,
			length: length_val || null,
			length_posted: length_posted || null,
			diameter: diameter || null,
			weight: weight || null,
			cap_type: cap_type || null,
			nib_stroke: nib_stroke || null,
			nib_material: nib_material || null,
			nib_flex: nib_flex || null,
			nib_modification: nib_modification || null,
			filler: filler || null,
			condition_rating: condition_rating,
			new_used: new_used || null,
			repair_required: repair_required || null,
			repair_cost: repair_cost,
			repaired_by: repaired_by || null,
			comments: comments || null,
			miscellaneous: miscellaneous || null,
			purchase_price: purchase_price,
			purchase_price_currency: purchase_price_currency || 'USD',
			purchase_date: purchase_date || null,
			purchased_from: purchased_from || null,
			shipping_cost: shipping_cost,
			retail_price: retail_price,
			selling_price: selling_price,
			selling_date: selling_date || null,
			sold_to: sold_to || null,
			current_value: current_value,
			valuation_date: valuation_date || null,
			quantity: quantity,
			photo_closed_url: photo_closed_url || null,
			photo_open_url: photo_open_url || null,
			photo_posted_url: photo_posted_url || null,
			photo_nib_url: photo_nib_url || null,
			photo_converter_url: photo_converter_url || null,
			photo_closed_caption: photo_closed_caption || null,
			photo_open_caption: photo_open_caption || null,
			photo_posted_caption: photo_posted_caption || null,
			photo_nib_caption: photo_nib_caption || null,
			photo_converter_caption: photo_converter_caption || null,
			first_impression: first_impression || null,
			appearance: appearance || null,
			design: design || null,
			nib_review: nib_review || null,
			filling_system_review: filling_system_review || null,
			cost_and_value: cost_and_value || null,
			conclusion: conclusion || null,
			first_impression_rating: first_impression_rating,
			appearance_rating: appearance_rating,
			design_rating: design_rating,
			nib_rating: nib_rating,
			filling_system_rating: filling_system_rating,
			cost_and_value_rating: cost_and_value_rating,
			updated_at: new Date().toISOString(),
		};

		if (isNew) {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) { error = 'Not authenticated'; saving = false; return; }
			data.user_id = user.id;
			const { data: newPen, error: err } = await supabase.from('pens').insert(data).select('id').single();
			if (err) { error = err.message; }
			else if (newPen) { goto(`/app/pens/${newPen.id}`); }
		} else {
			const { error: err } = await supabase.from('pens').update(data).eq('id', pen.id);
			if (err) { error = err.message; }
			else { success = 'Saved!'; setTimeout(() => success = '', 2000); }
		}
		saving = false;
	}

	async function handleDelete() {
		if (!confirm('Delete this pen? This cannot be undone.')) return;
		deleting = true;
		const { error: err } = await supabase.from('pens').delete().eq('id', pen.id);
		if (err) { error = err.message; deleting = false; }
		else { goto('/app/pens'); }
	}
</script>

<form onsubmit={handleSave} class="space-y-6">
	{#if error}
		<div class="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</div>
	{/if}
	{#if success}
		<div class="rounded-md bg-success/10 px-3 py-2 text-sm text-success">{success}</div>
	{/if}

	<!-- Identity -->
	<section class="rounded-xl border border-border bg-card p-4 md:p-6">
		<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Identity</h2>
		<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
			<div>
				<label for="model" class="mb-1 block text-sm font-medium text-foreground">Model</label>
				<input id="model" type="text" bind:value={model} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="manufacturer" class="mb-1 block text-sm font-medium text-foreground">Manufacturer</label>
				<input id="manufacturer" type="text" bind:value={manufacturer} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="pen_type" class="mb-1 block text-sm font-medium text-foreground">Type</label>
				<input id="pen_type" type="text" bind:value={pen_type} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="year_made" class="mb-1 block text-sm font-medium text-foreground">Year Made</label>
				<input id="year_made" type="text" bind:value={year_made} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div class="sm:col-span-2">
				<label for="description" class="mb-1 block text-sm font-medium text-foreground">Description</label>
				<textarea id="description" bind:value={description} rows="2" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
			</div>
		</div>
	</section>

	<!-- Physical -->
	<section class="rounded-xl border border-border bg-card p-4 md:p-6">
		<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Physical</h2>
		<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
			<div>
				<label for="color" class="mb-1 block text-sm font-medium text-foreground">Color</label>
				<input id="color" type="text" bind:value={color} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="primary_material" class="mb-1 block text-sm font-medium text-foreground">Primary Material</label>
				<input id="primary_material" type="text" bind:value={primary_material} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="body_material" class="mb-1 block text-sm font-medium text-foreground">Body Material</label>
				<input id="body_material" type="text" bind:value={body_material} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="size" class="mb-1 block text-sm font-medium text-foreground">Size</label>
				<input id="size" type="text" bind:value={size} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="length" class="mb-1 block text-sm font-medium text-foreground">Length</label>
				<input id="length" type="text" bind:value={length_val} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="length_posted" class="mb-1 block text-sm font-medium text-foreground">Length (posted)</label>
				<input id="length_posted" type="text" bind:value={length_posted} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="diameter" class="mb-1 block text-sm font-medium text-foreground">Diameter</label>
				<input id="diameter" type="text" bind:value={diameter} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="weight" class="mb-1 block text-sm font-medium text-foreground">Weight</label>
				<input id="weight" type="text" bind:value={weight} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="cap_type" class="mb-1 block text-sm font-medium text-foreground">Cap Type</label>
				<input id="cap_type" type="text" bind:value={cap_type} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
		</div>
	</section>

	<!-- Nib -->
	<section class="rounded-xl border border-border bg-card p-4 md:p-6">
		<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Nib</h2>
		<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
			<div>
				<label for="nib_stroke" class="mb-1 block text-sm font-medium text-foreground">Nib / Stroke</label>
				<input id="nib_stroke" type="text" bind:value={nib_stroke} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="nib_material" class="mb-1 block text-sm font-medium text-foreground">Nib Material</label>
				<input id="nib_material" type="text" bind:value={nib_material} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="nib_flex" class="mb-1 block text-sm font-medium text-foreground">Nib Flex</label>
				<input id="nib_flex" type="text" bind:value={nib_flex} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="nib_modification" class="mb-1 block text-sm font-medium text-foreground">Nib Modification</label>
				<input id="nib_modification" type="text" bind:value={nib_modification} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="filler" class="mb-1 block text-sm font-medium text-foreground">Filling System</label>
				<input id="filler" type="text" bind:value={filler} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
		</div>
	</section>

	<!-- Condition -->
	<section class="rounded-xl border border-border bg-card p-4 md:p-6">
		<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Condition</h2>
		<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
			<div>
				<label for="condition_rating" class="mb-1 block text-sm font-medium text-foreground">Condition (1-10)</label>
				<input id="condition_rating" type="number" min="1" max="10" bind:value={condition_rating} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="new_used" class="mb-1 block text-sm font-medium text-foreground">New / Used</label>
				<select id="new_used" bind:value={new_used} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
					<option value="">--</option>
					<option value="New">New</option>
					<option value="Used">Used</option>
				</select>
			</div>
			<div>
				<label for="repair_required" class="mb-1 block text-sm font-medium text-foreground">Repair Required</label>
				<input id="repair_required" type="text" bind:value={repair_required} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="repair_cost" class="mb-1 block text-sm font-medium text-foreground">Repair Cost</label>
				<input id="repair_cost" type="number" step="0.01" bind:value={repair_cost} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="repaired_by" class="mb-1 block text-sm font-medium text-foreground">Repaired By</label>
				<input id="repaired_by" type="text" bind:value={repaired_by} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
		</div>
	</section>

	<!-- Purchase / Sale -->
	<section class="rounded-xl border border-border bg-card p-4 md:p-6">
		<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Purchase & Sale</h2>
		<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
			<div>
				<label for="purchase_price" class="mb-1 block text-sm font-medium text-foreground">Purchase Price</label>
				<input id="purchase_price" type="number" step="0.01" bind:value={purchase_price} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="purchase_price_currency" class="mb-1 block text-sm font-medium text-foreground">Currency</label>
				<input id="purchase_price_currency" type="text" bind:value={purchase_price_currency} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="purchase_date" class="mb-1 block text-sm font-medium text-foreground">Purchase Date</label>
				<input id="purchase_date" type="date" bind:value={purchase_date} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="purchased_from" class="mb-1 block text-sm font-medium text-foreground">Purchased From</label>
				<input id="purchased_from" type="text" bind:value={purchased_from} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="shipping_cost" class="mb-1 block text-sm font-medium text-foreground">Shipping Cost</label>
				<input id="shipping_cost" type="number" step="0.01" bind:value={shipping_cost} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="retail_price" class="mb-1 block text-sm font-medium text-foreground">Retail Price</label>
				<input id="retail_price" type="number" step="0.01" bind:value={retail_price} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="selling_price" class="mb-1 block text-sm font-medium text-foreground">Selling Price</label>
				<input id="selling_price" type="number" step="0.01" bind:value={selling_price} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="selling_date" class="mb-1 block text-sm font-medium text-foreground">Selling Date</label>
				<input id="selling_date" type="date" bind:value={selling_date} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="sold_to" class="mb-1 block text-sm font-medium text-foreground">Sold To</label>
				<input id="sold_to" type="text" bind:value={sold_to} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="current_value" class="mb-1 block text-sm font-medium text-foreground">Current Value</label>
				<input id="current_value" type="number" step="0.01" bind:value={current_value} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="valuation_date" class="mb-1 block text-sm font-medium text-foreground">Valuation Date</label>
				<input id="valuation_date" type="date" bind:value={valuation_date} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
			<div>
				<label for="quantity" class="mb-1 block text-sm font-medium text-foreground">Quantity</label>
				<input id="quantity" type="number" min="1" bind:value={quantity} class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" />
			</div>
		</div>
	</section>

	<!-- Photos -->
	<section class="rounded-xl border border-border bg-card p-4 md:p-6">
		<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Photos</h2>
		<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
			{#each [
				['photo_closed_url', 'photo_closed_caption', 'Closed'],
				['photo_open_url', 'photo_open_caption', 'Open'],
				['photo_posted_url', 'photo_posted_caption', 'Posted'],
				['photo_nib_url', 'photo_nib_caption', 'Nib'],
				['photo_converter_url', 'photo_converter_caption', 'Converter'],
			] as [urlField, captionField, label]}
				<div>
					<p class="mb-1 text-sm font-medium text-foreground">{label}</p>
					{#if urlField === 'photo_closed_url' && photo_closed_url}
						<img src={photo_closed_url} alt={label} class="mb-2 h-24 w-24 rounded-lg object-cover" />
					{:else if urlField === 'photo_open_url' && photo_open_url}
						<img src={photo_open_url} alt={label} class="mb-2 h-24 w-24 rounded-lg object-cover" />
					{:else if urlField === 'photo_posted_url' && photo_posted_url}
						<img src={photo_posted_url} alt={label} class="mb-2 h-24 w-24 rounded-lg object-cover" />
					{:else if urlField === 'photo_nib_url' && photo_nib_url}
						<img src={photo_nib_url} alt={label} class="mb-2 h-24 w-24 rounded-lg object-cover" />
					{:else if urlField === 'photo_converter_url' && photo_converter_url}
						<img src={photo_converter_url} alt={label} class="mb-2 h-24 w-24 rounded-lg object-cover" />
					{/if}
					<input
						type="text"
						placeholder="Photo URL"
						value={urlField === 'photo_closed_url' ? photo_closed_url : urlField === 'photo_open_url' ? photo_open_url : urlField === 'photo_posted_url' ? photo_posted_url : urlField === 'photo_nib_url' ? photo_nib_url : photo_converter_url}
						oninput={(e) => {
							const val = (e.target as HTMLInputElement).value;
							if (urlField === 'photo_closed_url') photo_closed_url = val;
							else if (urlField === 'photo_open_url') photo_open_url = val;
							else if (urlField === 'photo_posted_url') photo_posted_url = val;
							else if (urlField === 'photo_nib_url') photo_nib_url = val;
							else photo_converter_url = val;
						}}
						class="mb-1 w-full rounded-lg border border-input bg-background px-3 py-1.5 text-xs text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
					/>
					<input
						type="text"
						placeholder="Caption"
						value={captionField === 'photo_closed_caption' ? photo_closed_caption : captionField === 'photo_open_caption' ? photo_open_caption : captionField === 'photo_posted_caption' ? photo_posted_caption : captionField === 'photo_nib_caption' ? photo_nib_caption : photo_converter_caption}
						oninput={(e) => {
							const val = (e.target as HTMLInputElement).value;
							if (captionField === 'photo_closed_caption') photo_closed_caption = val;
							else if (captionField === 'photo_open_caption') photo_open_caption = val;
							else if (captionField === 'photo_posted_caption') photo_posted_caption = val;
							else if (captionField === 'photo_nib_caption') photo_nib_caption = val;
							else photo_converter_caption = val;
						}}
						class="w-full rounded-lg border border-input bg-background px-3 py-1.5 text-xs text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
					/>
				</div>
			{/each}
		</div>
	</section>

	<!-- Comments -->
	<section class="rounded-xl border border-border bg-card p-4 md:p-6">
		<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Notes</h2>
		<div class="space-y-4">
			<div>
				<label for="comments" class="mb-1 block text-sm font-medium text-foreground">Comments</label>
				<textarea id="comments" bind:value={comments} rows="3" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
			</div>
			<div>
				<label for="miscellaneous" class="mb-1 block text-sm font-medium text-foreground">Miscellaneous</label>
				<textarea id="miscellaneous" bind:value={miscellaneous} rows="2" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
			</div>
		</div>
	</section>

	<!-- Review -->
	<section class="rounded-xl border border-border bg-card p-4 md:p-6">
		<h2 class="mb-4 font-serif text-lg font-semibold text-foreground">Review</h2>
		<div class="space-y-4">
			{#each [
				['first_impression', 'First Impression', 'first_impression_rating'],
				['appearance', 'Appearance', 'appearance_rating'],
				['design', 'Design', 'design_rating'],
				['nib_review', 'Nib', 'nib_rating'],
				['filling_system_review', 'Filling System', 'filling_system_rating'],
				['cost_and_value', 'Cost & Value', 'cost_and_value_rating'],
			] as [field, label, ratingField]}
				<div class="grid gap-3 sm:grid-cols-[1fr_100px]">
					<div>
						<label for={field} class="mb-1 block text-sm font-medium text-foreground">{label}</label>
						<textarea
							id={field}
							rows="2"
							value={field === 'first_impression' ? first_impression : field === 'appearance' ? appearance : field === 'design' ? design : field === 'nib_review' ? nib_review : field === 'filling_system_review' ? filling_system_review : cost_and_value}
							oninput={(e) => {
								const val = (e.target as HTMLTextAreaElement).value;
								if (field === 'first_impression') first_impression = val;
								else if (field === 'appearance') appearance = val;
								else if (field === 'design') design = val;
								else if (field === 'nib_review') nib_review = val;
								else if (field === 'filling_system_review') filling_system_review = val;
								else cost_and_value = val;
							}}
							class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
						></textarea>
					</div>
					<div>
						<label for={ratingField} class="mb-1 block text-sm font-medium text-foreground">Rating</label>
						<input
							id={ratingField}
							type="number"
							min="1"
							max="10"
							value={ratingField === 'first_impression_rating' ? first_impression_rating : ratingField === 'appearance_rating' ? appearance_rating : ratingField === 'design_rating' ? design_rating : ratingField === 'nib_rating' ? nib_rating : ratingField === 'filling_system_rating' ? filling_system_rating : cost_and_value_rating}
							oninput={(e) => {
								const val = (e.target as HTMLInputElement).valueAsNumber || null;
								if (ratingField === 'first_impression_rating') first_impression_rating = val;
								else if (ratingField === 'appearance_rating') appearance_rating = val;
								else if (ratingField === 'design_rating') design_rating = val;
								else if (ratingField === 'nib_rating') nib_rating = val;
								else if (ratingField === 'filling_system_rating') filling_system_rating = val;
								else cost_and_value_rating = val;
							}}
							class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
						/>
					</div>
				</div>
			{/each}
			<div>
				<label for="conclusion" class="mb-1 block text-sm font-medium text-foreground">Conclusion</label>
				<textarea id="conclusion" bind:value={conclusion} rows="3" class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
			</div>
		</div>
	</section>

	<!-- Actions -->
	<div class="flex items-center gap-3">
		<button
			type="submit"
			disabled={saving}
			class="rounded-lg bg-primary px-6 py-2.5 text-sm font-medium text-primary-foreground hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-ring disabled:opacity-50"
		>
			{saving ? 'Saving...' : isNew ? 'Create Pen' : 'Save Changes'}
		</button>
		<a href="/app/pens" class="rounded-lg border border-border px-4 py-2.5 text-sm font-medium text-muted-foreground hover:bg-secondary">
			Cancel
		</a>
		{#if !isNew}
			<button
				type="button"
				onclick={handleDelete}
				disabled={deleting}
				class="ml-auto rounded-lg border border-destructive px-4 py-2.5 text-sm font-medium text-destructive hover:bg-destructive/10 disabled:opacity-50"
			>
				{deleting ? 'Deleting...' : 'Delete'}
			</button>
		{/if}
	</div>
</form>
