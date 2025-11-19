WITH CustomerLastPurchase AS (
    SELECT
        Retailer_code,
        MAX(Date) AS last_purchase_date
    FROM
        `goexplore.daily_sales`
    GROUP BY
        Retailer_code
)
SELECT
    COUNT(DISTINCT CLP.Retailer_code) AS Customers_No_Purchase_Since_2018_05_01,
    (SELECT COUNT(DISTINCT Retailer_code) FROM `goexplore.daily_sales`) AS Total_Customers -- Total distinct customers from sales
FROM
    CustomerLastPurchase AS CLP
WHERE
    CLP.last_purchase_date < '2018-05-01' -- cutoff date
    OR CLP.last_purchase_date IS NULL;