let dark = $state(false);

if (typeof window !== 'undefined') {
	dark = document.documentElement.classList.contains('dark');
}

export function getTheme() {
	return {
		get dark() { return dark; },
		toggle() {
			dark = !dark;
			if (dark) {
				document.documentElement.classList.add('dark');
				localStorage.setItem('theme', 'dark');
			} else {
				document.documentElement.classList.remove('dark');
				localStorage.setItem('theme', 'light');
			}
		},
	};
}
