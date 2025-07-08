
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
top_selling_items AS (
    SELECT
        ss_item_sk,
        SUM(ss_quantity) AS total_store_quantity,
        SUM(ss_net_profit) AS total_store_profit
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ss_item_sk
),
combined_sales AS (
    SELECT 
        ws.ws_item_sk AS item_sk,
        ws.total_quantity AS web_quantity,
        ss.total_store_quantity AS store_quantity,
        COALESCE(ws.total_profit, 0) + COALESCE(ss.total_store_profit, 0) AS total_profit
    FROM 
        sales_summary ws
    FULL OUTER JOIN 
        top_selling_items ss ON ws.ws_item_sk = ss.ss_item_sk
),
avg_profit AS (
    SELECT 
        AVG(total_profit) AS average_profit 
    FROM 
        combined_sales
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cs.item_sk,
    cs.web_quantity,
    cs.store_quantity,
    cs.total_profit,
    ap.average_profit,
    CASE 
        WHEN cs.total_profit > ap.average_profit THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_status
FROM 
    combined_sales cs
JOIN 
    customer c ON c.c_customer_sk = (
        SELECT 
            c.c_customer_sk 
        FROM 
            web_sales ws 
        JOIN 
            customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        WHERE 
            ws.ws_item_sk = cs.item_sk
        LIMIT 1
    )
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
CROSS JOIN 
    avg_profit ap
WHERE 
    (cs.web_quantity IS NOT NULL OR cs.store_quantity IS NOT NULL)
    AND cs.total_profit IS NOT NULL
ORDER BY 
    cs.total_profit DESC, 
    ca.ca_city;
