
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.web_site_sk, ws_sold_date_sk
),
top_sales AS (
    SELECT 
        web_site_sk,
        total_sales,
        num_orders
    FROM sales_data
    WHERE rank <= 10
),
item_summary AS (
    SELECT 
        ws_item_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity_sold,
        AVG(ws_sales_price) AS avg_price
    FROM web_sales
    GROUP BY ws_item_sk
),
total_sales_per_item AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_sales,
        i.i_current_price,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(ws.ws_net_paid), 0) DESC) AS sales_rank
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_current_price
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(s.total_sales) AS total_sales,
        COUNT(s.num_orders) AS total_orders,
        ROUND(SUM(s.total_sales) / NULLIF(COUNT(s.num_orders), 0), 2) AS avg_order_value
    FROM sales_data s
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
)
SELECT 
    t.web_site_sk,
    t.total_sales,
    t.num_orders,
    i.i_item_id,
    i.total_sales AS item_sales,
    ds.total_sales AS daily_sales_total,
    ds.avg_order_value
FROM top_sales t
LEFT JOIN total_sales_per_item i ON i.sales_rank <= 5
LEFT JOIN daily_sales ds ON ds.total_orders > 100
WHERE (t.total_sales <> i.total_sales OR t.total_sales IS NULL)
AND COALESCE(t.num_orders, 0) > 0
ORDER BY t.total_sales DESC, i.total_sales DESC;
