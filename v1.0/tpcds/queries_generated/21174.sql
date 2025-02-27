
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit > 0
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        MAX(i.i_current_price) AS max_price,
        COALESCE(AVG(hd.hd_dep_count), 0) AS avg_dependency_count
    FROM 
        item i
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        household_demographics hd ON i.i_item_sk = hd.hd_demo_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
store_summary AS (
    SELECT 
        s.s_store_sk,
        s.s_store_id,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_id
),
customer_profit AS (
    SELECT 
        cu.c_customer_sk,
        SUM(ws.ws_net_profit) AS customer_net_profit
    FROM 
        customer cu
    LEFT JOIN 
        web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cu.c_customer_sk
)
SELECT 
    d.d_date_id,
    COALESCE(SUM(rp.ws_quantity), 0) AS total_quantity_sold,
    SUM(ds.total_store_profit) AS total_profit,
    COUNT(DISTINCT it.i_item_id) AS total_items_sold,
    MAX(it.max_price) AS highest_item_price,
    AVG(cs.catalog_sales_count) AS avg_catalog_sales_count,
    CASE 
        WHEN COUNT(DISTINCT cp.c_customer_sk) > 100 THEN 'Frenzied Shopper'
        ELSE 'Lone Wolf'
    END AS customer_type
FROM 
    date_dim d
LEFT JOIN 
    ranked_sales rp ON d.d_date_sk = rp.ws_sold_date_sk
LEFT JOIN 
    store_summary ds ON ds.total_sales_count > 5
LEFT JOIN 
    item_summary it ON it.catalog_sales_count > 0
LEFT JOIN 
    customer_profit cp ON TRUE
WHERE 
    d.d_year = 2023 AND 
    (it.total_catalog_profit IS NOT NULL OR it.avg_dependency_count IS NOT NULL)
GROUP BY 
    d.d_date_id
ORDER BY 
    total_profit DESC, d.d_date_id
LIMIT 100;
