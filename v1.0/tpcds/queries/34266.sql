
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        0 AS level,
        CAST(c.c_customer_id AS VARCHAR(255)) AS path
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.level + 1,
        CAST(ch.path || ' > ' || c.c_customer_id AS VARCHAR(255))
    FROM 
        customer c
    JOIN 
        customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
most_frequent_returned_items AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    ORDER BY 
        return_count DESC
    LIMIT 5
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ch.level,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    m.item_id,
    m.return_count
FROM 
    customer c
LEFT JOIN 
    customer_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
LEFT JOIN 
    sales_summary ss ON c.c_first_sales_date_sk = ss.ws_sold_date_sk
LEFT JOIN 
    (SELECT 
         i.i_item_sk AS item_id, 
         r.return_count 
     FROM 
         item i 
     JOIN 
         most_frequent_returned_items r ON i.i_item_sk = r.sr_item_sk) m ON m.item_id IS NOT NULL
WHERE 
    c.c_birth_country IS NOT NULL 
    AND LENGTH(c.c_first_name) > 3
ORDER BY 
    ch.level, c.c_last_name;
