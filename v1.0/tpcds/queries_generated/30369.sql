
WITH RECURSIVE sales_analysis AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
customer_age AS (
    SELECT 
        c_customer_sk,
        (YEAR(CURRENT_DATE) - c_birth_year) AS age
    FROM 
        customer
), 
demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state,
        COUNT(*) AS demographic_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state
), 
top_sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales_price,
        d.demographic_count
    FROM 
        sales_analysis s
    LEFT JOIN 
        demographics d ON s.ws_item_sk = d.cd_gender
    WHERE 
        s.rank = 1 AND 
        (d.demographic_count IS NOT NULL OR d.demographic_count IS NULL)
)
SELECT 
    (CASE 
        WHEN age < 30 THEN 'Youth'
        WHEN age BETWEEN 30 AND 60 THEN 'Adult'
        ELSE 'Senior' 
    END) AS age_group,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ts.total_quantity) AS total_quantity,
    SUM(ts.total_sales_price) AS total_sales
FROM 
    top_sales ts 
JOIN 
    customer_age ca ON ts.ws_item_sk = ca.c_customer_sk
LEFT JOIN 
    customer c ON c.c_customer_sk = ca.c_customer_sk
WHERE 
    ts.total_sales_price > 100
GROUP BY 
    age_group
ORDER BY 
    customer_count DESC
LIMIT 10;
