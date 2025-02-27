
WITH RECURSIVE address_cte AS (
    SELECT 
        ca_address_sk, 
        ca_address_id, 
        ca_city, 
        ca_state, 
        1 AS level 
    FROM customer_address
    WHERE ca_state IS NOT NULL
    
    UNION ALL
    
    SELECT 
        a.ca_address_sk, 
        a.ca_address_id, 
        a.ca_city, 
        a.ca_state, 
        ac.level + 1 
    FROM customer_address a
    JOIN address_cte ac ON a.ca_city = ac.ca_city
    WHERE a.ca_state IS NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_net_profit) AS max_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
promo_counts AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_promo_sk) AS promo_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count,
    COALESCE(ss.max_profit, 0) AS max_profit,
    COALESCE(pc.promo_count, 0) AS promo_count,
    a.ca_city,
    CASE 
        WHEN a.ca_state IS NULL THEN 'Unknown'
        ELSE a.ca_state 
    END AS state,
    CASE 
        WHEN ci.rn < 3 THEN 'Youth'
        ELSE 'Adult'
    END AS age_group
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN promo_counts pc ON ci.c_customer_sk = pc.ws_bill_customer_sk
LEFT JOIN address_cte a ON ci.c_customer_sk = a.ca_address_sk
WHERE (ss.total_sales IS NOT NULL OR pc.promo_count IS NOT NULL)
    AND (ci.c_last_name LIKE '%son%' OR a.ca_city IN (SELECT a.ca_city FROM customer_address a WHERE a.ca_state = 'NY'))
ORDER BY total_sales DESC, promo_count DESC
LIMIT 100;
