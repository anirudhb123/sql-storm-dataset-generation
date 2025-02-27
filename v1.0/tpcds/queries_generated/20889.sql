
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY COUNT(sr_item_sk) DESC) AS rnk
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerTrends AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent,
        SUM(CASE WHEN ws_sales_price > 50 THEN ws_quantity ELSE 0 END) AS high_value_purchases,
        MAX(ws_sales_price) AS max_purchase_price,
        AVG(CASE WHEN ws_sales_price IS NULL THEN 0 ELSE ws_sales_price END) AS avg_purchase_price
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
    GROUP BY c.c_customer_id
),
IncomeStatistics AS (
    SELECT 
        ib.ib_income_band_sk,
        COALESCE(AVG(hd_dep_count), 0) AS avg_dependents,
        SUM(hd_vehicle_count) AS total_vehicles,
        CASE 
            WHEN AVG(hd_dep_count) IS NULL THEN 'No Data'
            WHEN AVG(hd_dep_count) < 2 THEN 'Low'
            WHEN AVG(hd_dep_count) BETWEEN 2 AND 4 THEN 'Moderate'
            ELSE 'High'
        END AS dependency_band
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    ct.c_customer_id,
    rt.total_returns,
    ct.total_orders,
    ct.total_spent,
    is.avg_dependents,
    is.dependency_band,
    CASE 
        WHEN rt.total_returns IS NULL THEN 'No Returns'
        WHEN (rt.total_returns > 5 AND ct.total_orders IS NOT NULL) THEN 'Frequent Returner'
        ELSE 'Standard Customer'
    END AS customer_category
FROM CustomerTrends ct
LEFT JOIN RankedReturns rt ON ct.c_customer_id = rt.sr_customer_sk
LEFT JOIN IncomeStatistics is ON ct.avg_purchase_price IS NOT NULL
WHERE ct.total_orders > 0
AND (ct.high_value_purchases > 0 OR is.total_vehicles > 1)
ORDER BY ct.total_spent DESC, rt.total_returns DESC NULLS LAST;
