-- Retailer summary with CLTV logic
WITH retailer_activity AS (
  SELECT
    ds.Retailer_code AS retailer,
    r.Retailer_name AS retailer_name,
    r.Country AS country,
    COUNT(DISTINCT DATE(ds.Date)) AS purchase_days,
    MIN(DATE(ds.Date)) AS first_purchase,
    MAX(DATE(ds.Date)) AS last_purchase
  FROM `goexplore.daily_sales` ds
  JOIN `goexplore.retailers` r ON ds.Retailer_code = r.Retailer_code
  GROUP BY retailer, retailer_name, country
),

-- Average deal value: one “deal” = one day of activity
avg_deal_value AS (
  SELECT
    retailer,
    ROUND(AVG(daily_revenue), 2) AS avg_deal_value
  FROM (
    SELECT
      Retailer_code AS retailer,
      DATE(Date) AS order_date,
      SUM(Unit_sale_price * Quantity) AS daily_revenue
    FROM `goexplore.daily_sales`
    GROUP BY Retailer_code, DATE(Date)
  )
  GROUP BY retailer
),

-- Retailer-level summary including CLTV
retailer_summary AS (
  SELECT
    ra.retailer,
    ra.retailer_name,
    ra.country,
    ra.purchase_days,
    ra.first_purchase,
    ra.last_purchase,
    DATE_DIFF(DATE_TRUNC(ra.last_purchase, MONTH), DATE_TRUNC(ra.first_purchase, MONTH), MONTH) + 1 AS lifespan_months,
    ROUND(ra.purchase_days / (DATE_DIFF(DATE_TRUNC(ra.last_purchase, MONTH), DATE_TRUNC(ra.first_purchase, MONTH), MONTH) + 1), 2) AS purchase_frequency_per_month,
    adv.avg_deal_value,
    ROUND(
      (DATE_DIFF(DATE_TRUNC(ra.last_purchase, MONTH), DATE_TRUNC(ra.first_purchase, MONTH), MONTH) + 1) *
      (ra.purchase_days / (DATE_DIFF(DATE_TRUNC(ra.last_purchase, MONTH), DATE_TRUNC(ra.first_purchase, MONTH), MONTH) + 1)) *
      adv.avg_deal_value, 2) AS cltv
  FROM retailer_activity ra
  JOIN avg_deal_value adv ON ra.retailer = adv.retailer
),

-- Daily metrics per retailer per day
daily_metrics AS (
  SELECT
    ds.Retailer_code AS retailer,
    r.Country AS country,
    DATE(ds.Date) AS order_date,
    SUM(ds.Quantity) AS total_quantity,
    SUM(ds.Unit_sale_price * ds.Quantity) AS revenue,
    SUM((ds.Unit_sale_price - p.Unit_cost) * ds.Quantity) AS gross_profit,
    ROUND(
      SUM((ds.Unit_sale_price - p.Unit_cost) * ds.Quantity) /
      NULLIF(SUM(ds.Unit_sale_price * ds.Quantity), 0), 2
    ) AS gross_margin_percentage,
    om.order_method_type,
    p.Product_line
  FROM `goexplore.daily_sales` ds
  JOIN `goexplore.retailers` r ON ds.Retailer_code = r.Retailer_code
  JOIN `goexplore.products` p ON ds.Product_number = p.Product_number
  JOIN `goexplore.order_methods` om ON ds.Order_method_code = om.Order_method_code
  GROUP BY ds.Retailer_code, r.Country, DATE(ds.Date), om.order_method_type, p.Product_line
)

-- Final output
SELECT
  dm.order_date,
  rs.retailer,
  rs.retailer_name,
  rs.country,
  rs.first_purchase,
  rs.last_purchase,
  rs.purchase_days,
  rs.lifespan_months,
  rs.purchase_frequency_per_month,
  rs.avg_deal_value,
  rs.cltv,
  dm.total_quantity,
  dm.revenue,
  dm.gross_profit,
  dm.gross_margin_percentage,
  dm.order_method_type,
  dm.Product_line
FROM daily_metrics dm
LEFT JOIN retailer_summary rs ON dm.retailer = rs.retailer
ORDER BY dm.order_date, rs.cltv DESC;
