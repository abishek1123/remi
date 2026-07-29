/// Strips Markdown noise (asterisks, backticks, heading markers) from LLM
/// replies so they read cleanly on screen and aloud. Deliberately conservative:
/// only removes emphasis/code markers and leading heading hashes, so content
/// like "C#" or "a * b" mid-sentence is preserved.
String cleanReply(String input) {
  var t = input;
  t = t.replaceAll(RegExp(r'\*+'), ''); // **bold** / *italic*
  t = t.replaceAll(RegExp(r'`+'), ''); // `code`
  t = t.replaceAll(
      RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), ''); // # headings
  t = t.replaceAll(
      RegExp(r'^\s{0,3}[-•]\s+', multiLine: true), ''); // list bullets
  return t.trim();
}
