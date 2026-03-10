<script lang="ts">
	import { getAuth, signIn, signUp, resetPassword } from '$lib/stores/auth.svelte';
	import { goto } from '$app/navigation';

	const auth = getAuth();

	let mode: 'login' | 'signup' | 'forgot' = $state('login');
	let email = $state('');
	let password = $state('');
	let firstName = $state('');
	let lastName = $state('');
	let error = $state('');
	let message = $state('');
	let submitting = $state(false);

	// Redirect if already logged in
	$effect(() => {
		if (!auth.loading && auth.user) {
			goto('/app/pens');
		}
	});

	async function handleLogin(e: Event) {
		e.preventDefault();
		error = '';
		submitting = true;
		const result = await signIn(email, password);
		submitting = false;
		if (result.error) error = result.error.message;
	}

	async function handleSignup(e: Event) {
		e.preventDefault();
		error = '';
		if (password.length < 6) { error = 'Password must be at least 6 characters'; return; }
		submitting = true;
		const result = await signUp(email, password, firstName, lastName);
		submitting = false;
		if (result.error) {
			error = result.error.message;
		} else {
			message = 'Account created! You can now sign in.';
			mode = 'login';
			password = '';
		}
	}

	async function handleForgot(e: Event) {
		e.preventDefault();
		error = '';
		submitting = true;
		const result = await resetPassword(email);
		submitting = false;
		if (result.error) error = result.error.message;
		else message = 'Check your email for a password reset link.';
	}
</script>

{#if auth.loading}
	<div class="flex min-h-screen items-center justify-center bg-background">
		<div class="h-8 w-8 animate-spin rounded-full border-3 border-primary border-t-transparent"></div>
	</div>
{:else if !auth.user}
	<div class="flex min-h-screen bg-background">
		<!-- Left panel: decorative -->
		<div class="hidden w-1/2 items-center justify-center bg-primary lg:flex">
			<div class="max-w-md px-12 text-center">
				<div class="mb-8 flex justify-center">
					<div class="flex h-20 w-20 items-center justify-center rounded-2xl bg-white/10 backdrop-blur-sm">
						<svg class="h-10 w-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" /></svg>
					</div>
				</div>
				<h2 class="font-serif text-3xl font-bold text-white">Your collection, beautifully organized</h2>
				<p class="mt-4 text-base leading-relaxed text-white/70">
					Catalog, review, and manage your fountain pen collection from any device. Track purchases, write reviews, and showcase your pens.
				</p>
				<div class="mt-10 grid grid-cols-3 gap-4">
					<div class="rounded-xl bg-white/10 p-3 backdrop-blur-sm">
						<p class="text-2xl font-bold text-white">78</p>
						<p class="text-xs text-white/60">Fields per pen</p>
					</div>
					<div class="rounded-xl bg-white/10 p-3 backdrop-blur-sm">
						<p class="text-2xl font-bold text-white">210</p>
						<p class="text-xs text-white/60">Currencies</p>
					</div>
					<div class="rounded-xl bg-white/10 p-3 backdrop-blur-sm">
						<p class="text-2xl font-bold text-white">&infin;</p>
						<p class="text-xs text-white/60">Photos</p>
					</div>
				</div>
			</div>
		</div>

		<!-- Right panel: form -->
		<div class="flex flex-1 items-center justify-center px-6">
			<div class="w-full max-w-sm animate-slide-up">
				<!-- Logo -->
				<div class="mb-8 text-center lg:text-left">
					<div class="mb-4 inline-flex items-center gap-2">
						<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-primary text-sm font-bold text-primary-foreground">PV</div>
						<span class="font-serif text-2xl font-bold text-foreground">PenVault</span>
					</div>
					<p class="text-sm text-muted-foreground">
						{#if mode === 'login'}Sign in to your collection{:else if mode === 'signup'}Create your account{:else}Reset your password{/if}
					</p>
				</div>

				<!-- Messages -->
				{#if message}
					<div class="animate-slide-down mb-4 flex items-center gap-2 rounded-xl bg-success/10 px-4 py-3 text-sm text-success">
						<svg class="h-4 w-4 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" /></svg>
						{message}
					</div>
				{/if}
				{#if error}
					<div class="animate-slide-down mb-4 flex items-center gap-2 rounded-xl bg-destructive/10 px-4 py-3 text-sm text-destructive">
						<svg class="h-4 w-4 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z" /></svg>
						{error}
					</div>
				{/if}

				{#if mode === 'login'}
					<form onsubmit={handleLogin} class="space-y-4">
						<div>
							<label for="email" class="mb-1.5 block text-sm font-medium text-foreground">Email</label>
							<input id="email" type="email" bind:value={email} required autocomplete="email"
								class="w-full rounded-xl border border-input bg-card px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								placeholder="you@example.com"
							/>
						</div>
						<div>
							<label for="password" class="mb-1.5 block text-sm font-medium text-foreground">Password</label>
							<input id="password" type="password" bind:value={password} required autocomplete="current-password"
								class="w-full rounded-xl border border-input bg-card px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								placeholder="Your password"
							/>
						</div>
						<button type="submit" disabled={submitting}
							class="w-full rounded-xl bg-primary px-4 py-3 text-sm font-semibold text-primary-foreground shadow-sm transition-all hover:bg-primary/90 hover:shadow-md active:scale-[0.99] disabled:opacity-50"
						>
							{#if submitting}<span class="inline-flex items-center gap-2"><span class="h-4 w-4 animate-spin rounded-full border-2 border-primary-foreground border-t-transparent"></span> Signing in...</span>{:else}Sign In{/if}
						</button>
					</form>
					<div class="mt-5 space-y-2 text-center text-sm">
						<button onclick={() => { mode = 'forgot'; error = ''; message = ''; }} class="text-primary hover:underline">Forgot password?</button>
						<p class="text-muted-foreground">
							Don't have an account?
							<button onclick={() => { mode = 'signup'; error = ''; message = ''; }} class="text-primary hover:underline">Sign up</button>
						</p>
					</div>

				{:else if mode === 'signup'}
					<form onsubmit={handleSignup} class="space-y-4">
						<div class="grid grid-cols-2 gap-3">
							<div>
								<label for="first" class="mb-1.5 block text-sm font-medium text-foreground">First name</label>
								<input id="first" type="text" bind:value={firstName} required
									class="w-full rounded-xl border border-input bg-card px-4 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								/>
							</div>
							<div>
								<label for="last" class="mb-1.5 block text-sm font-medium text-foreground">Last name</label>
								<input id="last" type="text" bind:value={lastName} required
									class="w-full rounded-xl border border-input bg-card px-4 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								/>
							</div>
						</div>
						<div>
							<label for="signup-email" class="mb-1.5 block text-sm font-medium text-foreground">Email</label>
							<input id="signup-email" type="email" bind:value={email} required autocomplete="email"
								class="w-full rounded-xl border border-input bg-card px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								placeholder="you@example.com"
							/>
						</div>
						<div>
							<label for="signup-password" class="mb-1.5 block text-sm font-medium text-foreground">Password</label>
							<input id="signup-password" type="password" bind:value={password} required minlength="6" autocomplete="new-password"
								class="w-full rounded-xl border border-input bg-card px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								placeholder="At least 6 characters"
							/>
						</div>
						<button type="submit" disabled={submitting}
							class="w-full rounded-xl bg-primary px-4 py-3 text-sm font-semibold text-primary-foreground shadow-sm transition-all hover:bg-primary/90 hover:shadow-md active:scale-[0.99] disabled:opacity-50"
						>
							{#if submitting}<span class="inline-flex items-center gap-2"><span class="h-4 w-4 animate-spin rounded-full border-2 border-primary-foreground border-t-transparent"></span> Creating account...</span>{:else}Create Account{/if}
						</button>
					</form>
					<p class="mt-5 text-center text-sm text-muted-foreground">
						Already have an account?
						<button onclick={() => { mode = 'login'; error = ''; message = ''; }} class="text-primary hover:underline">Sign in</button>
					</p>

				{:else}
					<form onsubmit={handleForgot} class="space-y-4">
						<p class="text-sm text-muted-foreground">Enter your email and we'll send you a reset link.</p>
						<div>
							<label for="forgot-email" class="mb-1.5 block text-sm font-medium text-foreground">Email</label>
							<input id="forgot-email" type="email" bind:value={email} required autocomplete="email"
								class="w-full rounded-xl border border-input bg-card px-4 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
							/>
						</div>
						<button type="submit" disabled={submitting}
							class="w-full rounded-xl bg-primary px-4 py-3 text-sm font-semibold text-primary-foreground shadow-sm transition-all hover:bg-primary/90 hover:shadow-md active:scale-[0.99] disabled:opacity-50"
						>
							{#if submitting}<span class="inline-flex items-center gap-2"><span class="h-4 w-4 animate-spin rounded-full border-2 border-primary-foreground border-t-transparent"></span> Sending...</span>{:else}Send Reset Link{/if}
						</button>
					</form>
					<p class="mt-5 text-center text-sm text-muted-foreground">
						<button onclick={() => { mode = 'login'; error = ''; message = ''; }} class="text-primary hover:underline">Back to sign in</button>
					</p>
				{/if}

				<p class="mt-8 text-center text-xs text-muted-foreground/60">
					Inspired by <span class="font-medium">Fountain Pen Inventory</span> by Jon Rosen
				</p>
			</div>
		</div>
	</div>
{/if}
