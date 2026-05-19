/** Marker shared by legacy PST `constructEml()` multipart boundaries. */
export const OPEN_ARCHIVER_BOUNDARY = 'boundary-openarchiver';

const HTML_PART_HEADER =
	/Content-Type:\s*text\/html[^\r\n]*(?:\r?\n[^\r\n]+)*\r?\n\r?\n/i;

/**
 * Closing delimiters produced by legacy PST import (`--` + boundary token + optional `--`).
 * Uses `lastIndexOf` so we never rely on a regex where `[^\r\n]*` sits before a literal boundary.
 */
const LEGACY_PART_END_MARKERS = [
	`\r\n----${OPEN_ARCHIVER_BOUNDARY}_alt--`,
	`\n----${OPEN_ARCHIVER_BOUNDARY}_alt--`,
	`\r\n--${OPEN_ARCHIVER_BOUNDARY}_alt--`,
	`\n--${OPEN_ARCHIVER_BOUNDARY}_alt--`,
	`\r\n----${OPEN_ARCHIVER_BOUNDARY}--`,
	`\n----${OPEN_ARCHIVER_BOUNDARY}--`,
	`\r\n--${OPEN_ARCHIVER_BOUNDARY}--`,
	`\n--${OPEN_ARCHIVER_BOUNDARY}--`,
] as const;

export function findLegacyMimePartBodyEnd(tail: string): number {
	let end = tail.length;
	for (const marker of LEGACY_PART_END_MARKERS) {
		const index = tail.lastIndexOf(marker);
		if (index !== -1 && index < end) {
			end = index;
		}
	}
	return end;
}

/**
 * Pull the HTML section out of a broken multipart/alternative body (legacy PST import).
 */
export function extractHtmlPartFromMimePayload(source: string): string | null {
	const headerMatch = HTML_PART_HEADER.exec(source);
	if (!headerMatch || headerMatch.index === undefined) {
		return null;
	}

	const bodyStart = headerMatch.index + headerMatch[0].length;
	const tail = source.slice(bodyStart);
	const body = tail.slice(0, findLegacyMimePartBodyEnd(tail)).trim();
	return body.length > 0 ? body : null;
}

export function looksLikeMalformedMimePayload(content: string): boolean {
	return content.includes(OPEN_ARCHIVER_BOUNDARY);
}
