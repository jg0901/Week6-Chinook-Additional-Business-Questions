-- ============================================================================
-- GROW
-- Business question: Which top-selling tracks can we pair with unsold tracks
-- from the same album to create demand for dead catalogue items?
--
-- Fact:       InvoiceLine (Quantity, and the *absence* of a row)
-- Dimensions: Track, Album, Artist, Genre
--
-- A bundle needs an anchor (a track with proven demand) and dead stock to
-- carry. An album containing both is a ready-made bundle: the anchor supplies
-- the reason to buy, the unsold tracks supply the margin on inventory we
-- already own.
-- ============================================================================

CREATE OR REPLACE VIEW Week5.mart.vw_grow_bundle_candidates AS
WITH priced AS (
  SELECT
    t.track_id, t.track_name, t.artist_name, t.album_name, t.genre_name,
    CASE WHEN LOWER(t.media_type_name) LIKE '%video%' THEN 1.99 ELSE 0.99 END AS list_price
  FROM Week5.mart.dim_track t
),
sold AS (
  SELECT track_id, SUM(quantity) AS units_sold
  FROM Week5.mart.fact_invoiceline
  GROUP BY track_id
),
track_status AS (
  SELECT p.*, COALESCE(s.units_sold, 0) AS units_sold
  FROM priced p
  LEFT JOIN sold s ON p.track_id = s.track_id
)
SELECT
  artist_name,
  album_name,
  MAX(genre_name)   AS genre_name,
  COUNT(*) AS tracks_in_album,
  SUM(CASE WHEN units_sold > 0 THEN 1 ELSE 0 END) AS anchor_tracks,
  SUM(CASE WHEN units_sold = 0 THEN 1 ELSE 0 END) AS dead_tracks,
  SUM(units_sold)  AS album_units_sold,
  -- the anchor with the most demand, for the campaign creative
  MAX_BY(track_name, units_sold)  AS lead_anchor_track,
  ROUND(SUM(list_price), 2)  AS bundle_list_value,
  ROUND(SUM(CASE WHEN units_sold = 0 THEN list_price ELSE 0 END), 2) AS dead_stock_value,
  ROUND(SUM(CASE WHEN units_sold > 0 THEN list_price ELSE 0 END), 2) AS anchor_value,
  ROUND(100.0 * SUM(CASE WHEN units_sold > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS sell_through_pct
FROM track_status
GROUP BY artist_name, album_name
HAVING SUM(CASE WHEN units_sold > 0 THEN 1 ELSE 0 END) >= 1   -- has an anchor
   AND SUM(CASE WHEN units_sold = 0 THEN 1 ELSE 0 END) >= 1;  -- has dead stock


-- The bundle shortlist: most dead stock riding on proven demand
SELECT artist_name, album_name, genre_name, lead_anchor_track,
       tracks_in_album, anchor_tracks, dead_tracks,
       bundle_list_value, dead_stock_value, sell_through_pct
FROM Week5.mart.vw_grow_bundle_candidates
ORDER BY dead_tracks DESC, album_units_sold DESC
LIMIT 25;


-- How much dead stock is reachable this way, in total?
SELECT
  COUNT(*) AS candidate_albums,
  SUM(dead_tracks)  AS dead_tracks_reachable,
  ROUND(SUM(dead_stock_value), 2)  AS dead_stock_value,
  ROUND(AVG(tracks_in_album), 1)  AS avg_bundle_size,
  ROUND(AVG(sell_through_pct), 1)  AS avg_sell_through_pct
FROM Week5.mart.vw_grow_bundle_candidates;
