
WITH RECURSIVE top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_profit DESC
    LIMIT 5
),
inventory_status AS (
    SELECT 
        i.i_item_sk,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_quantity_on_hand
    FROM item i
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk
),
date_range AS (
    SELECT d.d_date_sk, d.d_date, d.d_year
    FROM date_dim d
    WHERE d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
customer_with_returns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.returned_date_sk) AS total_returns
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(cr.total_returns, 0) AS returns,
    COALESCE(i.total_quantity_on_hand, 0) AS inventory,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_net_paid_inc_tax) OVER (PARTITION BY d.d_year ORDER BY d.d_year) AS avg_net_paid_per_year
FROM top_customers tc
LEFT JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN inventory_status i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN customer_with_returns cr ON tc.c_customer_sk = cr.c_customer_sk
JOIN date_range d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY tc.c_customer_sk, tc.c_first_name, tc.c_last_name, cr.total_returns, i.total_quantity_on_hand
ORDER BY total_net_profit DESC;
