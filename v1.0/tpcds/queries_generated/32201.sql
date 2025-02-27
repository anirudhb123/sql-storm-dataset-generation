
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id
    UNION ALL
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        sales_cte s ON ws.ws_web_site_sk = s.web_site_id
    WHERE 
        s.total_sales < 10000
    GROUP BY 
        ws.web_site_id
),
customer_info AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        MAX(c.c_birth_year) - MIN(c.c_birth_year) AS customer_age_range,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_city
)
SELECT 
    ci.ca_city,
    ci.total_customers,
    ci.customer_age_range,
    ci.average_purchase_estimate,
    s.web_site_id,
    s.total_sales
FROM 
    customer_info ci
LEFT JOIN 
    sales_cte s ON s.web_site_id = (
        SELECT 
            ws.web_site_id 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_ext_sales_price = (
                SELECT MAX(ws_ext_sales_price) 
                FROM web_sales 
                WHERE ws.ws_web_site_sk = s.web_site_id
            )
        LIMIT 1
    )
WHERE 
    ci.total_customers IS NOT NULL
ORDER BY 
    ci.average_purchase_estimate DESC
LIMIT 20;
