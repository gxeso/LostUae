/**
 * LostUAE Similarity Model
 * ------------------------
 * ✔ Pure function
 * ✔ Cloud Function safe
 * ✔ Node 18 compatible
 */

/**
 * Normalize text:
 * - Lowercase
 * - Remove punctuation
 * - Tokenize
 */
function normalize(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter(Boolean);
}

/**
 * Calculate similarity using Jaccard index
 * Returns value between 0 and 1
 */
function calculateSimilarity(descriptionA, descriptionB) {
  if (
    !descriptionA ||
    !descriptionB ||
    typeof descriptionA !== "string" ||
    typeof descriptionB !== "string"
  ) {
    return 0;
  }

  const tokensA = new Set(normalize(descriptionA));
  const tokensB = new Set(normalize(descriptionB));

  if (tokensA.size === 0 || tokensB.size === 0) {
    return 0;
  }

  let common = 0;
  for (const token of tokensA) {
    if (tokensB.has(token)) {
      common++;
    }
  }

  const unionSize = new Set([...tokensA, ...tokensB]).size;
  const score = common / unionSize;

  return Math.max(0, Math.min(score, 1));
}

module.exports = {
  calculateSimilarity,
};
