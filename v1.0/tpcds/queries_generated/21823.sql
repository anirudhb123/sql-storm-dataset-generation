
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
joins_and_subqueries AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        (SELECT AVG(cs_sales.ws_net_profit) 
         FROM web_sales ws_sales  
         WHERE ws_sales.ws_ship_date_sk = cs.cs_ship_date_sk) AS avg_net_profit
    FROM 
        customer_address ca
    LEFT JOIN catalog_sales cs ON ca.ca_address_sk = cs.cs_bill_addr_sk
    WHERE 
        ca.ca_state IN (SELECT DISTINCT ca_state FROM customer_address WHERE ca_city LIKE 'New%')
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    cs.c_customer_sk,
    cs.gender,
    cs.order_count,
    cs.avg_order_value,
    jas.ca_city,
    jas.ca_state,
    jas.catalog_sales_count,
    jas.avg_net_profit,
    rs.ws_sales_price,
    rs.total_quantity
FROM 
    customer_stats cs
JOIN 
    joins_and_subqueries jas ON cs.c_customer_sk = jas.ca_address_sk
LEFT JOIN 
    ranked_sales rs ON cs.order_count > 5 AND rs.rank_price < 10
WHERE 
    cs.avg_order_value IS NOT NULL
    AND (jas.catalog_sales_count > 0 OR jas.avg_net_profit IS NOT NULL)
ORDER BY 
    cs.order_count DESC, jas.avg_net_profit DESC;
