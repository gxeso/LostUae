/**
 * LostUAE Similarity Model
 * ------------------------
 * ✔ Pure function — no external dependencies
 * ✔ Cloud Function safe (Node 20 compatible)
 * ✔ Hybrid model: weighted unigram Jaccard + bigram Jaccard
 * ✔ Stopword removal (English + common filler words)
 * ✔ Basic suffix stemming (wallet/wallets, phone/phones, etc.)
 */

/* ─────────────────────────────────────────
   STOPWORDS
   Common English words that carry no
   meaningful signal for item matching.
   ───────────────────────────────────────── */
const STOPWORDS = new Set([
  "a", "an", "the", "and", "or", "but", "if", "in", "on", "at",
  "to", "for", "of", "with", "by", "from", "is", "it", "its",
  "was", "are", "were", "be", "been", "being", "have", "has",
  "had", "do", "does", "did", "will", "would", "could", "should",
  "may", "might", "shall", "can", "not", "no", "nor", "so",
  "yet", "both", "either", "neither", "each", "few", "more",
  "most", "other", "some", "such", "than", "too", "very",
  "just", "also", "this", "that", "these", "those", "my", "your",
  "his", "her", "our", "their", "i", "we", "you", "he", "she",
  "they", "me", "him", "us", "them", "what", "which", "who",
  "whom", "when", "where", "why", "how", "all", "any", "both",
  "about", "above", "after", "before", "between", "into", "through",
  "during", "near", "while", "up", "down", "out", "off", "over",
  "under", "again", "then", "once", "here", "there", "s", "t",
  "got", "get", "lost", "found", "please", "help", "looking",
  "item", "object", "thing", "one", "two", "three",
]);

/* ─────────────────────────────────────────
   STEMMING
   Strips common English suffixes so that
   "wallets" → "wallet", "phones" → "phone",
   "missing" → "miss", "dropped" → "drop"
   ───────────────────────────────────────── */
function stem(word) {
  if (word.length <= 3) return word;

  // Order matters — longest suffix first
  if (word.endsWith("ings"))  return word.slice(0, -4);
  if (word.endsWith("ing"))   return word.slice(0, -3);
  if (word.endsWith("tion"))  return word.slice(0, -4);
  if (word.endsWith("ness"))  return word.slice(0, -4);
  if (word.endsWith("ment"))  return word.slice(0, -4);
  if (word.endsWith("less"))  return word.slice(0, -4);
  if (word.endsWith("ful"))   return word.slice(0, -3);
  if (word.endsWith("able"))  return word.slice(0, -4);
  if (word.endsWith("ible"))  return word.slice(0, -4);
  if (word.endsWith("edly"))  return word.slice(0, -4);
  if (word.endsWith("ely"))   return word.slice(0, -3);
  if (word.endsWith("ly"))    return word.slice(0, -2);
  if (word.endsWith("ed"))    return word.slice(0, -2);
  if (word.endsWith("er"))    return word.slice(0, -2);
  if (word.endsWith("est"))   return word.slice(0, -3);
  if (word.endsWith("ies"))   return word.slice(0, -3) + "y";
  if (word.endsWith("es") && word.length > 4) return word.slice(0, -2);
  if (word.endsWith("s") && word.length > 3)  return word.slice(0, -1);

  return word;
}

/* ─────────────────────────────────────────
   NORMALIZE
   Lowercase → strip punctuation → tokenize
   → remove stopwords → stem
   ───────────────────────────────────────── */
function normalize(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter(Boolean)
    .filter((w) => !STOPWORDS.has(w))
    .map(stem);
}

/* ─────────────────────────────────────────
   BIGRAMS
   Generates consecutive token pairs for
   phrase-level matching.
   e.g. ["black","leather","wallet"]
     → ["black_leather", "leather_wallet"]
   ───────────────────────────────────────── */
function bigrams(tokens) {
  const result = [];
  for (let i = 0; i < tokens.length - 1; i++) {
    result.push(`${tokens[i]}_${tokens[i + 1]}`);
  }
  return result;
}

/* ─────────────────────────────────────────
   JACCARD SIMILARITY
   Shared / Union for any two arrays.
   ───────────────────────────────────────── */
function jaccard(arrA, arrB) {
  const setA = new Set(arrA);
  const setB = new Set(arrB);

  if (setA.size === 0 && setB.size === 0) return 1; // both empty → identical
  if (setA.size === 0 || setB.size === 0) return 0;

  let common = 0;
  for (const token of setA) {
    if (setB.has(token)) common++;
  }

  const unionSize = new Set([...setA, ...setB]).size;
  return common / unionSize;
}

/* ─────────────────────────────────────────
   CALCULATE SIMILARITY  (main export)
   Weighted hybrid:
     60% unigram Jaccard  (keyword overlap)
   + 40% bigram  Jaccard  (phrase overlap)
   Returns a value in [0, 1].
   ───────────────────────────────────────── */
function calculateSimilarity(descriptionA, descriptionB) {
  if (
    !descriptionA ||
    !descriptionB ||
    typeof descriptionA !== "string" ||
    typeof descriptionB !== "string"
  ) {
    return 0;
  }

  const tokensA = normalize(descriptionA);
  const tokensB = normalize(descriptionB);

  if (tokensA.length === 0 || tokensB.length === 0) return 0;

  const unigramScore = jaccard(tokensA, tokensB);

  const bigramsA = bigrams(tokensA);
  const bigramsB = bigrams(tokensB);

  // If either description is a single meaningful word, bigrams are empty.
  // Fall back to pure unigram score in that case.
  const bigramScore =
    bigramsA.length === 0 || bigramsB.length === 0
      ? unigramScore
      : jaccard(bigramsA, bigramsB);

  const hybrid = 0.6 * unigramScore + 0.4 * bigramScore;

  return Math.max(0, Math.min(Number(hybrid.toFixed(4)), 1));
}

module.exports = { calculateSimilarity };
