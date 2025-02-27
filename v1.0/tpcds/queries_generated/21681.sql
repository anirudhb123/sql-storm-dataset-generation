
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rnk
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_ext_sales_price) AS total_sales_value,
        MAX(ws_net_profit) AS highest_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
IncomeDistribution AS (
    SELECT
        ib_income_band_sk,
        CASE 
            WHEN ib_lower_bound IS NULL THEN 'Unknown'
            WHEN ib_upper_bound IS NULL THEN 'Infinity'
            ELSE CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound)
        END AS income_band_range
    FROM income_band
),
 DailySales AS (
    SELECT 
        d.d_date, 
        COALESCE(SUM(ws.ws_net_paid), 0) AS daily_net_paid,
        DENSE_RANK() OVER (ORDER BY d.d_date DESC) AS rank_days
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COALESCE(r.total_returns, 0) AS total_returns,
    r.total_return_amount,
    s.total_sales,
    s.total_sales_value,
    CASE 
        WHEN s.highest_profit IS NULL THEN 'No sales'
        ELSE CONCAT('$', ROUND(s.highest_profit, 2))
    END AS highest_profit,
    i.income_band_range,
    d.daily_net_paid,
    d.rank_days
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN RankedReturns r ON r.sr_item_sk = c.c_customer_sk
LEFT JOIN SalesSummary s ON s.ws_item_sk = c.c_customer_sk
LEFT JOIN IncomeDistribution i ON i.ib_income_band_sk = c.c_current_cdemo_sk
CROSS JOIN DailySales d
WHERE ca.ca_state = 'CA'
AND (r.total_returns IS NULL OR r.total_returns > 2)
AND (d.rank_days BETWEEN 1 AND 5 OR d.daily_net_paid > 1000)
ORDER BY total_returns DESC, highest_profit DESC;
