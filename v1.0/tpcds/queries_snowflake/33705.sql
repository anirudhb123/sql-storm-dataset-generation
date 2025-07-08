
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_sold_date_sk,
        1 AS depth
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30

    UNION ALL

    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        cs_sold_date_sk,
        depth + 1
    FROM 
        catalog_sales
    JOIN sales_data ON cs_item_sk = ws_item_sk
    WHERE 
        cs_sold_date_sk >= ws_sold_date_sk
)

SELECT 
    ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(w.ws_net_profit) AS total_profit,
    AVG(w.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN c.c_customer_sk END) AS male_customers,
    COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN c.c_customer_sk END) AS female_customers
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales w ON w.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IS NOT NULL
AND 
    EXISTS (
        SELECT 
            1 
        FROM 
            sales_data sd
        WHERE 
            sd.ws_order_number = w.ws_order_number
            AND sd.depth < 5
    )
GROUP BY 
    ca_state
ORDER BY 
    total_profit DESC
LIMIT 10;
