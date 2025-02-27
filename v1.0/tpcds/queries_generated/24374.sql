
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL 
        AND ws.ws_sales_price > 0
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(COALESCE(cs.cs_net_profit, 0)) AS total_profit
    FROM 
        customer c
    LEFT JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
address_agg AS (
    SELECT 
        ca.ca_country,
        AVG(COALESCE(cs.cs_sales_price, 0)) AS avg_sales_price,
        SUM(CASE WHEN cs.cs_quantity > 5 THEN cs.cs_quantity ELSE 0 END) AS total_large_sales
    FROM 
        customer_address ca
    LEFT JOIN store_sales cs ON ca.ca_address_sk = cs.ss_addr_sk
    GROUP BY 
        ca.ca_country
)
SELECT 
    cs.c_customer_sk,
    cs.order_count,
    cs.total_profit,
    aa.ca_country,
    aa.avg_sales_price,
    aa.total_large_sales
FROM 
    customer_summary cs
JOIN (
    SELECT 
        ca.ca_country,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN cs.cs_quantity > 5 THEN cs.cs_quantity ELSE 0 END) DESC) AS country_rank
    FROM 
        customer_address ca
    LEFT JOIN store_sales cs ON ca.ca_address_sk = cs.ss_addr_sk
    GROUP BY 
        ca.ca_country
) ranked_countries ON ranked_countries.country_rank <= 5
JOIN address_agg aa ON ranked_countries.ca_country = aa.ca_country
WHERE 
    EXISTS (
        SELECT 1 FROM ranked_sales rs WHERE rs.ws_order_number = cs.order_count
    )
ORDER BY 
    cs.total_profit DESC, 
    aa.avg_sales_price ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
