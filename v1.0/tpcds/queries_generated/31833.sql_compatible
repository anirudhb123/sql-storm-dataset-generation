
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_sk
),
customer_return_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS total_web_returns,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk
),
item_rankings AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
)
SELECT 
    s.web_site_sk,
    s.total_profit,
    s.total_orders,
    cr.total_web_returns,
    cr.total_return_amount,
    i.i_item_desc,
    i.sales_rank
FROM sales_summary s
LEFT JOIN customer_return_stats cr ON s.web_site_sk = cr.c_customer_sk
JOIN item_rankings i ON i.sales_rank <= 10
WHERE s.total_profit > 10000
ORDER BY s.total_profit DESC, cr.total_web_returns ASC;
