
WITH RECURSIVE customer_ranks AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000000 AND 1050000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
sales_data AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        COUNT(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_net_paid) AS total_paid
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk IS NOT NULL
    GROUP BY 
        cs.cs_item_sk, cs.cs_order_number
), 
item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM 
        item i 
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
), 
aggregated_data AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        COALESCE(i.item_count, 0) AS item_count,
        COALESCE(s.total_quantity_sold, 0) AS catalog_quantity,
        COALESCE(s.total_net_profit, 0) AS catalog_profit
    FROM 
        customer_ranks r
    LEFT JOIN (
        SELECT 
            cs.cs_bill_customer_sk,
            COUNT(DISTINCT cs.cs_item_sk) AS item_count
        FROM 
            catalog_sales cs 
        GROUP BY 
            cs.cs_bill_customer_sk
    ) i ON i.cs_bill_customer_sk = r.c_customer_sk
    LEFT JOIN sales_data s ON s.cs_order_number IN (
        SELECT 
            ss_ticket_number 
        FROM 
            store_sales 
        WHERE 
            ss_customer_sk = r.c_customer_sk 
            AND ss_net_profit > 0
    )
)

SELECT 
    a.c_customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.item_count,
    a.catalog_quantity,
    a.catalog_profit,
    CASE 
        WHEN a.catalog_profit IS NULL THEN 'No Profit' 
        WHEN a.catalog_profit < 0 THEN 'Loss' 
        ELSE 'Profit' 
    END AS profit_status,
    COUNT(DISTINCT i.i_item_id) OVER (PARTITION BY a.c_customer_sk) AS unique_items_purchased,
    MAX(a.catalog_profit) OVER (PARTITION BY a.c_customer_sk) AS max_profit
FROM 
    aggregated_data a
JOIN 
    item_sales i ON a.c_customer_sk = i.i_item_sk
WHERE 
    a.catalog_quantity IS NOT NULL OR a.item_count IS NOT NULL
ORDER BY 
    a.catalog_profit DESC, a.c_first_name ASC
LIMIT 100 OFFSET 10;
