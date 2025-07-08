
WITH RECURSIVE CategoryHierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_category AS category,
        1 AS level
    FROM 
        item i
    WHERE 
        i.i_category IS NOT NULL
    UNION ALL
    SELECT 
        ch.i_item_sk,
        ch.i_item_id,
        CONCAT(ch.category, ' > ', i2.i_category) AS category,
        level + 1
    FROM 
        CategoryHierarchy ch
    JOIN 
        item i2 ON ch.i_item_sk = i2.i_item_sk 
    WHERE 
        i2.i_category IS NOT NULL AND ch.level < 5
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
BestSellingItems AS (
    SELECT 
        s.ws_item_sk,
        ch.category,
        s.total_net_profit,
        s.total_orders,
        ROW_NUMBER() OVER (PARTITION BY ch.category ORDER BY s.total_net_profit DESC) AS category_pos
    FROM 
        SalesData s
    JOIN 
        CategoryHierarchy ch ON s.ws_item_sk = ch.i_item_sk
)

SELECT 
    bh.category,
    bh.ws_item_sk,
    MAX(bh.total_net_profit) AS max_profit,
    SUM(bh.total_orders) AS total_orders,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    LISTAGG(DISTINCT c.c_email_address, ', ') WITHIN GROUP (ORDER BY c.c_email_address) AS customer_emails
FROM 
    BestSellingItems bh
LEFT JOIN 
    customer c ON bh.ws_item_sk = c.c_current_addr_sk
WHERE 
    bh.category_pos <= 10
GROUP BY 
    bh.category, bh.ws_item_sk
ORDER BY 
    bh.category, max_profit DESC;
