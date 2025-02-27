
WITH RECURSIVE sales_trends AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    HAVING SUM(ws_net_profit) > 0
),
ranked_sales AS (
    SELECT
        d.d_date,
        s.ws_item_sk,
        s.total_net_profit,
        s.profit_rank,
        COALESCE(ore.order_revenue, 0) AS order_revenue
    FROM sales_trends s
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN (
        SELECT
            ws_item_sk,
            SUM(ws_ext_sales_price) AS order_revenue
        FROM web_sales
        WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 LIMIT 1)
        GROUP BY ws_item_sk
    ) ore ON s.ws_item_sk = ore.ws_item_sk
    WHERE s.profit_rank <= 5
),
customer_ranking AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_net_profit) AS total_spent,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS customer_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    r.d_date,
    r.ws_item_sk,
    r.total_net_profit,
    r.order_revenue,
    cr.c_customer_sk,
    cr.total_spent,
    cr.customer_rank
FROM ranked_sales r
JOIN customer_ranking cr ON r.ws_item_sk = (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_bill_customer_sk = cr.c_customer_sk
    ORDER BY ws_sold_date_sk DESC
    LIMIT 1
)
WHERE r.total_net_profit IS NOT NULL
AND r.total_net_profit > (
    SELECT AVG(total_net_profit) 
    FROM ranked_sales 
    WHERE ws_item_sk = r.ws_item_sk
)
ORDER BY r.d_date DESC, cr.total_spent DESC;
