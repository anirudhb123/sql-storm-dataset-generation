
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_cdemo_sk,
        1 AS level
    FROM 
        customer
    WHERE 
        c_birth_country IS NOT NULL

    UNION ALL

    SELECT 
        c.customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE 
        c.c_birth_country IS NOT NULL
)

SELECT 
    d.d_year,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
    COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank,
    MAX(CASE WHEN cd_gender = 'F' THEN cd_purchase_estimate END) AS max_female_purchase_estimate,
    MIN(CASE WHEN cd_marital_status = 'M' AND cd_credit_rating = 'High' THEN cd_dep_count END) AS min_marital_high_credit_dependents
FROM 
    date_dim d 
LEFT JOIN 
    web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN 
    customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk
WHERE 
    d.d_year >= 2020
    AND d.d_month_seq IN (1, 2, 3)
GROUP BY 
    d.d_year
HAVING 
    SUM(ws.ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales WHERE ws_sold_date_sk <= d.d_date_sk)
ORDER BY 
    d.d_year DESC;
