
WITH RECURSIVE income_band_cte AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band AS ib
    JOIN income_band_cte AS ib_cte ON ib.ib_income_band_sk = ib_cte.ib_income_band_sk
    WHERE ib.ib_lower_bound < ib_cte.ib_upper_bound
), sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS avg_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales AS ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws.ws_item_sk
), customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_item_sk IN (SELECT is.i_item_sk FROM inventory AS is WHERE is.inv_quantity_on_hand < 50)
    GROUP BY c.c_customer_sk, cd.cd_marital_status
), return_details AS (
    SELECT
        wr.wr_returning_customer_sk,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt,
        COUNT(wr.wr_order_number) AS total_returns
    FROM web_returns AS wr
    GROUP BY wr.wr_returning_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_spent,
    COALESCE(rd.avg_return_amt, 0) AS avg_return,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.total_quantity,
    ss.total_profit,
    (CASE
        WHEN ss.profit_rank = 1 THEN 'Top Performer'
        WHEN ss.profit_rank <= 5 THEN 'High Performer'
        ELSE 'Regular Performer'
    END) AS performance_category
FROM customer_summary AS cs
LEFT JOIN return_details AS rd ON cs.c_customer_sk = rd.wr_returning_customer_sk
LEFT JOIN income_band_cte AS ib ON cs.total_spent BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
JOIN sales_summary AS ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
WHERE cs.total_orders > 10
ORDER BY cs.total_spent DESC, ss.total_profit DESC;
