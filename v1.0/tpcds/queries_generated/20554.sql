
WITH RankedReturns AS (
    SELECT cr_returning_customer_sk, 
           cr_item_sk, 
           SUM(cr_return_quantity) AS total_return_quantity,
           ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rnk
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk, cr_item_sk
), 
ReturnCounts AS (
    SELECT cr_returning_customer_sk, COUNT(*) AS total_returns
    FROM RankedReturns
    WHERE rnk <= 5
    GROUP BY cr_returning_customer_sk
),
CustomerPurchases AS (
    SELECT c.c_customer_id,
           SUM(ws_ext_sales_price) AS total_spent,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_id
),
IncomeDistribution AS (
    SELECT ib_income_band_sk, 
           CASE 
               WHEN ib_lower_bound IS NULL THEN 'Unknown'
               ELSE CONCAT('From ', ib_lower_bound, ' to ', ib_upper_bound)
           END AS income_range,
           COUNT(DISTINCT hd_demo_sk) AS household_count
    FROM household_demographics h
    JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
)
SELECT c.c_first_name, c.c_last_name, cp.total_spent, 
       rc.total_returns AS top_returning_customers, 
       id.income_range
FROM customer c
JOIN CustomerPurchases cp ON c.c_customer_id = cp.c_customer_id
LEFT JOIN ReturnCounts rc ON c.c_customer_sk = rc.cr_returning_customer_sk
LEFT JOIN IncomeDistribution id ON c.c_current_hdemo_sk = id.hd_demo_sk
WHERE cp.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchases)
  AND rc.total_returns IS NOT NULL
ORDER BY cp.total_spent DESC, rc.total_returns DESC
LIMIT 10;
