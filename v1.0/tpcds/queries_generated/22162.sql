
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_ext_sales_price DESC) AS rank,
        ws_ext_sales_price,
        ws_net_profit,
        ws_quantity,
        COALESCE(NULLIF(ws_ext_sales_price, 0), NULL) AS safe_sales_price
    FROM web_sales ws
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 12
    )
),
profit_summary AS (
    SELECT 
        w.warehouse_name,
        SUM(rs.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders,
        AVG(rs.safe_sales_price) AS avg_sales_price
    FROM ranked_sales rs
    JOIN warehouse w ON rs.web_site_sk = w.warehouse_sk
    GROUP BY w.warehouse_name
),
top_profit_warehouses AS (
    SELECT warehouse_name, total_net_profit,
           RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM profit_summary
)
SELECT 
    t.warehouse_name,
    t.total_net_profit,
    t.profit_rank,
    CASE 
        WHEN t.profit_rank <= 5 THEN 'Top 5 Profit'
        ELSE 'Other'
    END AS profit_category,
    COALESCE((
        SELECT STRING_AGG(CONVERT(VARCHAR, c.c_first_name + ' ' + c.c_last_name), ', ')
        FROM customer c
        INNER JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        WHERE ws.ws_order_number IN (
            SELECT rs.ws_order_number
            FROM ranked_sales rs
            WHERE rs.web_site_sk IN (SELECT w.warehouse_sk FROM warehouse w WHERE w.warehouse_name = t.warehouse_name)
        )
    ), 'No Customers') AS customer_names
FROM top_profit_warehouses t
WHERE total_net_profit IS NOT NULL AND profit_rank <= 10
ORDER BY profit_rank;
