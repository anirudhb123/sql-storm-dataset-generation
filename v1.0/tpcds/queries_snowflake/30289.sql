
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        1 AS level,
        ws_sales_price AS base_price
    FROM 
        web_sales
    WHERE 
        ws_net_profit > 0
    UNION ALL
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        sh.level + 1,
        sh.base_price * (1 - cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0)) 
    FROM 
        catalog_sales cs
    JOIN 
        sales_hierarchy sh ON cs.cs_item_sk = sh.ws_item_sk AND cs.cs_order_number = sh.ws_order_number
    WHERE 
        cs.cs_sales_price >= sh.base_price 
),
item_performance AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000 
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
best_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        ip.total_sold,
        ip.unique_orders,
        ip.avg_net_profit,
        ROW_NUMBER() OVER (ORDER BY ip.avg_net_profit DESC) AS rank
    FROM 
        item_performance ip 
    JOIN
        item i ON ip.i_item_sk = i.i_item_sk
    WHERE 
        ip.total_sold > 100 
)
SELECT 
    bi.i_item_sk,
    bi.i_item_desc,
    bi.total_sold,
    bi.unique_orders,
    bi.avg_net_profit,
    CASE 
        WHEN bi.rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS performance_category,
    COALESCE((SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = bi.i_item_sk), 0) AS total_returns
FROM 
    best_items bi
LEFT JOIN 
    inventory inv ON bi.i_item_sk = inv.inv_item_sk
WHERE 
    (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand > 0) 
ORDER BY 
    bi.rank;
