import { supabase } from '$lib/supabase';
import type { User, Session } from '@supabase/supabase-js';

let user = $state<User | null>(null);
let session = $state<Session | null>(null);
let loading = $state(true);

// Initialize auth state
supabase.auth.getSession().then(({ data }) => {
	session = data.session;
	user = data.session?.user ?? null;
	loading = false;
});

// Listen for auth changes
supabase.auth.onAuthStateChange((_event, newSession) => {
	session = newSession;
	user = newSession?.user ?? null;
	loading = false;
});

export function getAuth() {
	return {
		get user() { return user; },
		get session() { return session; },
		get loading() { return loading; },
	};
}

export async function signIn(email: string, password: string) {
	const { error } = await supabase.auth.signInWithPassword({ email, password });
	return { error };
}

export async function signUp(email: string, password: string, firstName: string, lastName: string) {
	const { error } = await supabase.auth.signUp({
		email,
		password,
		options: {
			data: { first_name: firstName, last_name: lastName },
		},
	});
	return { error };
}

export async function signOut() {
	await supabase.auth.signOut();
}

export async function resetPassword(email: string) {
	const { error } = await supabase.auth.resetPasswordForEmail(email, {
		redirectTo: `${window.location.origin}/reset-password`,
	});
	return { error };
}
