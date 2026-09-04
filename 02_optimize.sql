-- ============================================================================
-- OPTIMIZE
-- Business question: How should we size and price these bundles to raise
-- average order value?
--
-- Fact:       InvoiceLine (LineAmount, Quantity)
-- Dimensions: Track, Album
--
-- A bundle only helps if the discounted price still clears today's average
-- order value. Below that, we are moving stock but shrinking the basket.
--
-- This models three discount tiers against the live baseline rather than a
-- hardcoded figure, so it stays correct if the data changes.
-- ============================================================================

CREATE OR REPLACE VIEW Week5.mart.vw_optimize_bundle_pricing AS
SELECT
  c.artist_name,
  c.album_name,
  c.genre_name,
  c.tracks_in_album                                   AS bundle_size,
  c.dead_tracks,
  c.bundle_list_value,
  b.avg_order_value                                   AS current_aov,
  ROUND(c.bundle_list_value * 0.90, 2)                AS price_at_10pct_off,
  ROUND(c.bundle_list_value * 0.80, 2)                AS price_at_20pct_off,
  ROUND(c.bundle_list_value * 0.70, 2)                AS price_at_30pct_off,
  ROUND(c.bundle_list_value * 0.80 - b.avg_order_value, 2) AS aov_uplift_at_20pct_off,
  CASE
    WHEN c.bundle_list_value * 0.70 >= b.avg_order_value THEN 'Safe to 30% off'
    WHEN c.bundle_list_value * 0.80 >= b.avg_order_value THEN 'Safe to 20% off'
    WHEN c.bundle_list_value * 0.90 >= b.avg_order_value THEN 'Safe to 10% off'
    ELSE 'Too small to discount'
  END AS pricing_headroom
FROM Week5.mart.vw_grow_bundle_candidates c
CROSS JOIN Week5.mart.vw_bundle_baseline b;

-- COMMAND ----------

-- Which bundle sizes have pricing headroom?
SELECT
  pricing_headroom,
  COUNT(*)                        AS bundles,
  ROUND(AVG(bundle_size), 1)      AS avg_bundle_size,
  ROUND(AVG(bundle_list_value), 2) AS avg_list_value,
  SUM(dead_tracks)                AS dead_tracks_covered
FROM Week5.mart.vw_optimize_bundle_pricing
GROUP BY pricing_headroom
ORDER BY bundles DESC;

-- COMMAND ----------

-- The minimum bundle size that clears current AOV at each discount tier
WITH b AS (SELECT avg_order_value FROM Week5.mart.vw_bundle_baseline)
SELECT
  '10% off' AS discount, CEIL(b.avg_order_value / (0.99 * 0.90)) AS min_tracks_to_clear_aov FROM b
UNION ALL
SELECT '20% off', CEIL(b.avg_order_value / (0.99 * 0.80)) FROM b
UNION ALL
SELECT '30% off', CEIL(b.avg_order_value / (0.99 * 0.70)) FROM b
UNION ALL
SELECT '40% off', CEIL(b.avg_order_value / (0.99 * 0.60)) FROM b;
