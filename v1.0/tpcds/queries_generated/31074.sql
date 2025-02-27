
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
    HAVING 
        total_quantity > 0
),
address_with_counts AS (
    SELECT 
        ca_address_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address CA
    LEFT JOIN 
        customer C ON CA.ca_address_sk = C.c_current_addr_sk
    GROUP BY 
        ca_address_sk
),
final_sales AS (
    SELECT 
        C.c_customer_id,
        CA.ca_city,
        COALESCE(SUM(S.total_profit), 0) AS city_total_profit,
        DATEDIFF(DAY, MIN(C.c_birth_year), CURRENT_DATE) AS customer_age
    FROM 
        customer C
    LEFT JOIN 
        address_with_counts CA ON C.c_current_addr_sk = CA.ca_address_sk
    LEFT JOIN 
        sales_cte S ON C.c_customer_sk = S.ws_item_sk
    WHERE 
        C.c_preferred_cust_flag = 'Y'
    GROUP BY 
        C.c_customer_id, CA.ca_city
)
SELECT 
    f.c_customer_id,
    f.ca_city,
    f.city_total_profit,
    f.customer_age,
    RANK() OVER (ORDER BY f.city_total_profit DESC) AS profit_rank
FROM 
    final_sales f
WHERE 
    f.city_total_profit IS NOT NULL
    AND f.customer_age > 18
ORDER BY 
    f.city_total_profit DESC;
