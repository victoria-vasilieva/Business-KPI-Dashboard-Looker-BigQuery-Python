SELECT
  Retailer_name,
  Type,
  Country,
  PARSE_DATE('%Y%m%d', CONCAT(CAST(EXTRACT(YEAR FROM date) AS STRING), LPAD(CAST(EXTRACT(MONTH FROM date) AS STRING), 2, '0'), '01')) AS Month_Date,
  Product_number,
  Order_method_type,
  SUM(Quantity) AS Quantity,
  SUM(Unit_price) AS Unit_price,
  SUM(Unit_sale_price) AS Unit_sale_price,
  CAST(SUM(Quantity * Unit_sale_price) AS int) AS Revenue
FROM
  `goexplore-464508.goexplore.daily_sales`
JOIN
  `goexplore.order_methods` m USING (Order_method_code)
JOIN
  `goexplore.retailers` r USING (Retailer_code)
GROUP BY
  Retailer_name, Product_number, Order_method_type, Month_Date, Type, Country
ORDER BY
  Month_Date ASC