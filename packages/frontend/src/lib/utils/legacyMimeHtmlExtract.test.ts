import { describe, expect, it } from 'vitest';
import {
	extractHtmlPartFromMimePayload,
	findLegacyMimePartBodyEnd,
} from './legacyMimeHtmlExtract';

describe('extractHtmlPartFromMimePayload', () => {
	it('extracts full HTML through legacy boundary, not at Outlook style comments', () => {
		const tail =
			'<html><head><style>\n--></style></head><body>Hello</body></html>\n\n\n------boundary-openarchiver_alt--\n';
		const source = `Content-Type: text/html; charset=utf-8\r\n\r\n${tail}`;

		const html = extractHtmlPartFromMimePayload(source);
		expect(html).toContain('Hello');
		expect(html).toContain('<body>');
		expect(html).not.toContain('boundary-openarchiver_alt--');
	});

	it('stops at the last boundary when decoy text appears earlier in HTML', () => {
		const tail =
			'<html>\n--foo boundary-openarchiver decoy</html>REAL\n\n\n------boundary-openarchiver_alt--\n';
		const source = `Content-Type: text/html\r\n\r\n${tail}`;

		const html = extractHtmlPartFromMimePayload(source);
		expect(html).toContain('REAL');
		expect(html).not.toContain('decoy');
	});

	it('findLegacyMimePartBodyEnd uses last closing marker', () => {
		const tail = 'aaa\n--foo boundary-openarchiver\nbbb\n\n------boundary-openarchiver_alt--\n';
		expect(findLegacyMimePartBodyEnd(tail)).toBe(tail.lastIndexOf('\n\n------boundary-openarchiver_alt--'));
	});
});
