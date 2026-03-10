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
		if (result.error) {
			error = result.error.message;
		}
	}

	async function handleSignup(e: Event) {
		e.preventDefault();
		error = '';
		if (password.length < 6) {
			error = 'Password must be at least 6 characters';
			return;
		}
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
		if (result.error) {
			error = result.error.message;
		} else {
			message = 'Check your email for a password reset link.';
		}
	}
</script>

{#if auth.loading}
	<div class="flex min-h-screen items-center justify-center bg-background">
		<div class="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
	</div>
{:else if !auth.user}
	<div class="flex min-h-screen items-center justify-center bg-background px-4">
		<div class="w-full max-w-sm">
			<!-- Logo -->
			<div class="mb-8 text-center">
				<h1 class="font-serif text-3xl font-bold text-foreground">Fountain Pen Inventory</h1>
				<p class="mt-2 text-sm text-muted-foreground">Your collection, cataloged.</p>
			</div>

			<!-- Card -->
			<div class="rounded-xl border border-border bg-card p-6 shadow-sm">
				{#if message}
					<div class="mb-4 rounded-md bg-success/10 px-3 py-2 text-sm text-success">{message}</div>
				{/if}
				{#if error}
					<div class="mb-4 rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</div>
				{/if}

				{#if mode === 'login'}
					<form onsubmit={handleLogin} class="space-y-4">
						<div>
							<label for="email" class="mb-1 block text-sm font-medium text-foreground">Email</label>
							<input
								id="email"
								type="email"
								bind:value={email}
								required
								autocomplete="email"
								class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								placeholder="you@example.com"
							/>
						</div>
						<div>
							<label for="password" class="mb-1 block text-sm font-medium text-foreground">Password</label>
							<input
								id="password"
								type="password"
								bind:value={password}
								required
								autocomplete="current-password"
								class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								placeholder="Your password"
							/>
						</div>
						<button
							type="submit"
							disabled={submitting}
							class="w-full rounded-lg bg-primary px-4 py-2.5 text-sm font-medium text-primary-foreground hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-ring disabled:opacity-50"
						>
							{submitting ? 'Signing in...' : 'Sign In'}
						</button>
					</form>
					<div class="mt-4 space-y-2 text-center text-sm">
						<button onclick={() => { mode = 'forgot'; error = ''; message = ''; }} class="text-primary hover:underline">
							Forgot password?
						</button>
						<p class="text-muted-foreground">
							Don't have an account?
							<button onclick={() => { mode = 'signup'; error = ''; message = ''; }} class="text-primary hover:underline">Sign up</button>
						</p>
					</div>

				{:else if mode === 'signup'}
					<form onsubmit={handleSignup} class="space-y-4">
						<div class="grid grid-cols-2 gap-3">
							<div>
								<label for="first" class="mb-1 block text-sm font-medium text-foreground">First name</label>
								<input
									id="first"
									type="text"
									bind:value={firstName}
									required
									class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								/>
							</div>
							<div>
								<label for="last" class="mb-1 block text-sm font-medium text-foreground">Last name</label>
								<input
									id="last"
									type="text"
									bind:value={lastName}
									required
									class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								/>
							</div>
						</div>
						<div>
							<label for="signup-email" class="mb-1 block text-sm font-medium text-foreground">Email</label>
							<input
								id="signup-email"
								type="email"
								bind:value={email}
								required
								autocomplete="email"
								class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								placeholder="you@example.com"
							/>
						</div>
						<div>
							<label for="signup-password" class="mb-1 block text-sm font-medium text-foreground">Password</label>
							<input
								id="signup-password"
								type="password"
								bind:value={password}
								required
								minlength="6"
								autocomplete="new-password"
								class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
								placeholder="At least 6 characters"
							/>
						</div>
						<button
							type="submit"
							disabled={submitting}
							class="w-full rounded-lg bg-primary px-4 py-2.5 text-sm font-medium text-primary-foreground hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-ring disabled:opacity-50"
						>
							{submitting ? 'Creating account...' : 'Create Account'}
						</button>
					</form>
					<p class="mt-4 text-center text-sm text-muted-foreground">
						Already have an account?
						<button onclick={() => { mode = 'login'; error = ''; message = ''; }} class="text-primary hover:underline">Sign in</button>
					</p>

				{:else}
					<form onsubmit={handleForgot} class="space-y-4">
						<p class="text-sm text-muted-foreground">Enter your email and we'll send you a reset link.</p>
						<div>
							<label for="forgot-email" class="mb-1 block text-sm font-medium text-foreground">Email</label>
							<input
								id="forgot-email"
								type="email"
								bind:value={email}
								required
								autocomplete="email"
								class="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
							/>
						</div>
						<button
							type="submit"
							disabled={submitting}
							class="w-full rounded-lg bg-primary px-4 py-2.5 text-sm font-medium text-primary-foreground hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-ring disabled:opacity-50"
						>
							{submitting ? 'Sending...' : 'Send Reset Link'}
						</button>
					</form>
					<p class="mt-4 text-center text-sm text-muted-foreground">
						<button onclick={() => { mode = 'login'; error = ''; message = ''; }} class="text-primary hover:underline">Back to sign in</button>
					</p>
				{/if}
			</div>

			<p class="mt-6 text-center text-xs text-muted-foreground">
				Based on <span class="font-medium">Fountain Pen Inventory</span> by Jon Rosen
			</p>
		</div>
	</div>
{/if}
