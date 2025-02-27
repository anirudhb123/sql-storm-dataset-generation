
WITH RECURSIVE StoreHierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        1 AS level
    FROM 
        store
    WHERE 
        s_closed_date_sk IS NULL

    UNION ALL

    SELECT 
        s2.s_store_sk,
        CONCAT(s1.s_store_name, ' > ', s2.s_store_name),
        sh.level + 1
    FROM 
        StoreHierarchy sh
    JOIN 
        store s1 ON sh.s_store_sk = s1.s_store_sk
    JOIN 
        store s2 ON s1.s_store_sk = s2.s_store_sk
    WHERE 
        s2.s_closed_date_sk IS NULL
)

SELECT 
    ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(DATE_PART('dow', d.d_date)) AS max_day_of_week,
    STRING_AGG(DISTINCT CONCAT(wp_type, ': ', wp_url), '; ') AS web_page_info
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN 
    StoreHierarchy sh ON sh.s_store_sk = c.c_current_addr_sk
WHERE 
    (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
    AND (ws.ws_sales_price IS NOT NULL OR ws.ws_net_paid IS NOT NULL)
    AND d.d_year = 2023
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY 
    total_net_profit DESC;
