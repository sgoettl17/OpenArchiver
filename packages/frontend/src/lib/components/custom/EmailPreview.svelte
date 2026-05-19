<script lang="ts">
	import PostalMime, { type Attachment, type Email } from 'postal-mime';
	import type { Buffer } from 'buffer';
	import { t } from '$lib/translations';
	import { encode } from 'html-entities';
	import {
		extractHtmlPartFromMimePayload,
		looksLikeMalformedMimePayload,
	} from '$lib/utils/legacyMimeHtmlExtract';

	let {
		raw,
		rawHtml,
	}: { raw?: Buffer | { type: 'Buffer'; data: number[] } | undefined; rawHtml?: string } =
		$props();

	let parsedEmail: Email | null = $state(null);
	let isLoading = $state(true);

	/** Converts an ArrayBuffer to a base64-encoded string. */
	function arrayBufferToBase64(buffer: ArrayBuffer): string {
		const bytes = new Uint8Array(buffer);
		let binary = '';
		for (let i = 0; i < bytes.byteLength; i++) {
			binary += String.fromCharCode(bytes[i]);
		}
		return btoa(binary);
	}

	function resolveDisplayHtml(html: string, attachments: Attachment[]): string {
		let content = html;
		if (looksLikeMalformedMimePayload(content)) {
			const extracted = extractHtmlPartFromMimePayload(content);
			if (extracted) {
				content = extracted;
			}
		}
		return resolveContentIdReferences(content, attachments);
	}

	/**
	 * Replaces `cid:` references in HTML with inline base64 data URIs
	 * sourced from the parsed email attachments.
	 */
	function resolveContentIdReferences(html: string, attachments: Attachment[]): string {
		if (!attachments || attachments.length === 0) return html;

		const cidMap = new Map<string, string>();
		for (const attachment of attachments) {
			if (!attachment.contentId) continue;

			const cid = attachment.contentId.replace(/^<|>$/g, '');

			let base64Content: string;
			if (typeof attachment.content === 'string') {
				base64Content = attachment.content;
			} else {
				base64Content = arrayBufferToBase64(attachment.content);
			}

			cidMap.set(cid, `data:${attachment.mimeType};base64,${base64Content}`);
		}

		if (cidMap.size === 0) return html;

		return html.replace(/cid:([^\s"']+)/gi, (match, cid) => {
			return cidMap.get(cid) ?? match;
		});
	}

	// By adding a <base> tag, all relative and absolute links in the HTML document
	// will open in a new tab by default.
	let emailHtml = $derived(() => {
		if (parsedEmail?.html) {
			return `<base target="_blank" />${resolveDisplayHtml(parsedEmail.html, parsedEmail.attachments)}`;
		}
		if (parsedEmail?.text) {
			const extractedHtml = extractHtmlPartFromMimePayload(parsedEmail.text);
			if (extractedHtml) {
				return `<base target="_blank" />${resolveDisplayHtml(
					extractedHtml,
					parsedEmail.attachments
				)}`;
			}
			const safeHtmlContent: string = encode(parsedEmail.text);
			return `<base target="_blank" /><div>${safeHtmlContent.replaceAll('\n', '<br>')}</div>`;
		}
		if (rawHtml) {
			const extractedHtml = extractHtmlPartFromMimePayload(rawHtml);
			if (extractedHtml) {
				return `<base target="_blank" />${extractedHtml}`;
			}
			return `<base target="_blank" />${rawHtml}`;
		}
		return null;
	});

	$effect(() => {
		async function parseEmail() {
			if (raw) {
				try {
					let buffer: Uint8Array;
					if ('type' in raw && raw.type === 'Buffer') {
						buffer = new Uint8Array(raw.data);
					} else {
						buffer = new Uint8Array(raw as Buffer);
					}
					const parsed = await new PostalMime().parse(buffer);
					parsedEmail = parsed;
				} catch (error) {
					console.error('Failed to parse email:', error);
				} finally {
					isLoading = false;
				}
			} else {
				isLoading = false;
			}
		}
		parseEmail();
	});
</script>

<div class="mt-2 rounded-md border bg-white p-4">
	{#if isLoading}
		<p>{$t('app.components.email_preview.loading')}</p>
	{:else if emailHtml()}
		<iframe
			title={$t('app.archive.email_preview')}
			srcdoc={emailHtml()}
			class="h-[600px] w-full border-none"
		></iframe>
	{:else if raw}
		<p>{$t('app.components.email_preview.render_error')}</p>
	{:else}
		<p class="text-gray-500">{$t('app.components.email_preview.not_available')}</p>
	{/if}
</div>
