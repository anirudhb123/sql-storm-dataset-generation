
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_item_sk
),
ranked_sales AS (
    SELECT 
        s.ws_sold_date_sk,
        s.ws_item_sk,
        s.total_quantity,
        s.total_profit,
        ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY s.total_profit DESC) AS rank
    FROM sales_data s
),
top_sales AS (
    SELECT 
        r.ws_item_sk, 
        r.total_quantity, 
        r.total_profit,
        ca.item_desc AS ca_item_desc,
        ca.category AS ca_category
    FROM ranked_sales r
    JOIN item i ON r.ws_item_sk = i.i_item_sk
    LEFT JOIN (
        SELECT 
            i_category_id, 
            LISTAGG(i_item_desc, ', ') WITHIN GROUP (ORDER BY i_item_desc) AS ca_item_desc, 
            MAX(i_category) AS ca_category
        FROM item
        GROUP BY i_category_id
    ) ca ON i.i_category_id = ca.i_category_id
    WHERE r.rank <= 10
)
SELECT 
    w.w_warehouse_name,
    SUM(ts.total_quantity) AS total_sales_quantity,
    AVG(ts.total_profit) AS average_profit,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    MAX(c.c_birth_year) AS latest_birth_year
FROM top_sales ts
JOIN warehouse w ON w.w_warehouse_sk = (SELECT inv.inv_warehouse_sk FROM inventory inv WHERE inv.inv_item_sk = ts.ws_item_sk LIMIT 1)
JOIN customer c ON ts.ws_item_sk = c.c_current_hdemo_sk
WHERE ts.total_profit IS NOT NULL
GROUP BY w.w_warehouse_name
HAVING AVG(ts.total_profit) > (
    SELECT AVG(total_profit) FROM top_sales
)
ORDER BY total_sales_quantity DESC;
