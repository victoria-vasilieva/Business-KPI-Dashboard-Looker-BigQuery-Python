WITH CustomerLastPurchase AS (
    SELECT
        Retailer_code,
        MAX(Date) AS last_purchase_date
    FROM
        `goexplore.daily_sales`
    GROUP BY
        Retailer_code
),
ChurnedCustomers AS (
    SELECT
        CLP.Retailer_code
    FROM
        CustomerLastPurchase AS CLP
    WHERE
        CLP.last_purchase_date < '2018-05-01'
        OR CLP.last_purchase_date IS NULL
)
SELECT
    ds.Retailer_code,
    r.Retailer_name, 
    round(SUM(ds.Unit_price*ds.Quantity), 0) AS Total_Revenue_Generated
FROM
    `goexplore.daily_sales` AS ds
JOIN
    ChurnedCustomers AS CC
ON
    ds.Retailer_code = CC.Retailer_code
JOIN
    `goexplore.retailers` AS r 
ON
    ds.Retailer_code = r.Retailer_code
GROUP BY
    ds.Retailer_code,
    r.Retailer_name 
ORDER BY
    Total_Revenue_Generated DESC;