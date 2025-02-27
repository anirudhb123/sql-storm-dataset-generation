
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_paid) AS avg_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_net_paid
    FROM sales_summary ss
    JOIN item ON ss.ws_item_sk = item.i_item_sk
    WHERE ss.total_quantity > 100
    ORDER BY ss.total_sales DESC
    LIMIT 10
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.avg_net_paid
FROM customer ci
JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN top_items ti ON ws.ws_item_sk = ti.ws_item_sk
WHERE ci.c_birth_year BETWEEN 1980 AND 1990
ORDER BY ti.total_sales DESC;
