
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        0 AS level,
        c.c_current_cdemo_sk
    FROM 
        customer c
    WHERE 
        c.c_preferred_cust_flag IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.level + 1 AS level,
        ch.c_current_cdemo_sk
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk 
    WHERE 
        ch.level < 10
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
),
filtered_items AS (
    SELECT 
        i.i_item_sk,
        is.total_sold,
        is.avg_price,
        ir.r_reason_desc
    FROM 
        item_stats is
    JOIN 
        catalog_returns cr ON is.i_item_sk = cr.cr_item_sk
    JOIN 
        reason ir ON cr.cr_reason_sk = ir.r_reason_sk
    WHERE 
        is.total_sold > (SELECT AVG(total_sold) FROM item_stats)
)

SELECT 
    ch.level,
    ch.c_first_name,
    ch.c_last_name,
    COALESCE(fi.total_sold, 0) AS total_sold,
    fi.avg_price,
    STRING_AGG(DISTINCT fi.r_reason_desc, ', ') AS return_reasons
FROM 
    customer_hierarchy ch
LEFT JOIN 
    filtered_items fi ON ch.c_current_cdemo_sk = fi.i_item_sk
GROUP BY 
    ch.level, ch.c_first_name, ch.c_last_name
HAVING 
    COALESCE(SUM(fi.total_sold), 0) > 0
ORDER BY 
    ch.level, ch.c_last_name, ch.c_first_name;
