
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_profit
    FROM RecursiveSales
    WHERE rank <= 10 
),
DecileCalculation AS (
    SELECT 
        ib_income_band_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM household_demographics h
    JOIN customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY ib_income_band_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
CombinedSales AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        d.customer_count
    FROM TopItems ti
    LEFT JOIN CustomerReturns cr ON ti.ws_item_sk = cr.sr_item_sk
    JOIN DecileCalculation d ON d.ib_income_band_sk = (
        SELECT ib_income_band_sk 
        FROM income_band ib 
        WHERE total_profit BETWEEN ib_lower_bound AND ib_upper_bound
        LIMIT 1
    )
)
SELECT 
    c.c_customer_id,
    CASE 
        WHEN total_profit >= 1000 THEN 'High Value'
        WHEN total_profit BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    SUM(total_quantity - total_returns) AS net_sales
FROM CombinedSales cs
JOIN customer c ON c.c_customer_sk = (
    SELECT c_customer_sk
    FROM web_sales ws 
    WHERE ws.ws_item_sk = cs.ws_item_sk 
    ORDER BY ws_sold_date_sk DESC 
    LIMIT 1
)
GROUP BY c.c_customer_id, customer_value
HAVING COALESCE(SUM(total_quantity - total_returns), 0) > 0 
ORDER BY net_sales DESC, c.c_customer_id ASC;
