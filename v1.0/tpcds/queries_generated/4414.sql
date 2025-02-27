
WITH item_sales AS (
    SELECT 
        i.i_item_sk, 
        i.i_product_name, 
        COALESCE(SUM(ws.ws_quantity), 0) AS web_sales_quantity,
        COALESCE(SUM(cs.cs_quantity), 0) AS catalog_sales_quantity,
        COALESCE(SUM(ss.ss_quantity), 0) AS store_sales_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) + COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
),
ranked_items AS (
    SELECT 
        i.*,
        RANK() OVER (ORDER BY total_net_profit DESC) AS sales_rank
    FROM 
        item_sales si
    JOIN 
        item i ON si.i_item_sk = i.i_item_sk
)

SELECT 
    ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
    c.cc_call_center_id AS call_center_id,
    r.r_reason_desc AS return_reason,
    si.i_product_name AS item_name,
    si.web_sales_quantity,
    si.catalog_sales_quantity,
    si.store_sales_quantity,
    si.total_net_profit
FROM 
    customer ci
JOIN 
    call_center c ON ci.c_current_hdemo_sk = c.cc_call_center_sk
JOIN 
    store_returns sr ON ci.c_customer_sk = sr.sr_customer_sk
JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN 
    ranked_items si ON sr.sr_item_sk = si.i_item_sk
WHERE 
    ci.c_birth_year BETWEEN 1980 AND 1990
    AND (si.total_net_profit > 1000 OR si.store_sales_quantity > 100)
    AND si.sales_rank <= 10
ORDER BY 
    si.total_net_profit DESC;
