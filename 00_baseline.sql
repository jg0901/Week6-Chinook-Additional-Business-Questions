-- ============================================================================
-- Baseline — what we are trying to beat
-- Source: Week5.mart.fact_invoiceline
-- ============================================================================

CREATE OR REPLACE VIEW Week5.mart.vw_bundle_baseline AS
SELECT
  COUNT(DISTINCT invoice_id) AS orders,
  SUM(quantity)  AS tracks_sold,
  ROUND(SUM(line_amount), 2) AS revenue,
  ROUND(SUM(line_amount) / COUNT(DISTINCT invoice_id), 2)   AS avg_order_value,
  ROUND(SUM(quantity) * 1.0 / COUNT(DISTINCT invoice_id), 2) AS avg_tracks_per_order
FROM Week5.mart.fact_invoiceline;



SELECT * FROM Week5.mart.vw_bundle_baseline;
