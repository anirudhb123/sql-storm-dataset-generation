
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
            ELSE cd.cd_marital_status 
        END AS marital_status,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_dep_count DESC) AS income_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
)
SELECT 
    ca.ca_city,
    COALESCE(MAX(s.sales_price), 0) AS max_sales_price,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    STRING_AGG(DISTINCT ci.marital_status, ', ') AS marital_status_distribution
FROM 
    customer_address ca
LEFT JOIN 
    store_sales ss ON ca.ca_address_sk = ss.ss_addr_sk
LEFT JOIN 
    ranked_sales rs ON ss.ss_item_sk = rs.web_site_sk AND rs.sales_rank <= 5
LEFT JOIN 
    customer_info ci ON ci.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND YEAR(ca.ca_zip) % 5 = 0
GROUP BY 
    ca.ca_city
HAVING 
    MAX(ss.ss_list_price) > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_ship_date_sk >= 20230101)
ORDER BY 
    unique_customers DESC
LIMIT 10;
