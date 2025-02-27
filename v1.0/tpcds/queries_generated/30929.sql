
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_bill_customer_sk, 
        SUM(cs_ext_sales_price) AS total_sales, 
        1 AS level
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk = (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)
    GROUP BY 
        cs_bill_customer_sk
    UNION ALL
    SELECT 
        cs_bill_customer_sk, 
        SUM(cs_ext_sales_price) + sh.total_sales AS total_sales, 
        level + 1
    FROM 
        catalog_sales cs
    JOIN 
        sales_hierarchy sh ON cs_bill_customer_sk = sh.cs_bill_customer_sk
    WHERE 
        cs_sold_date_sk < (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)
    GROUP BY 
        cs_bill_customer_sk, sh.total_sales, level
),
latest_promotions AS (
    SELECT 
        p.p_promo_id, 
        p.p_promo_name, 
        p.p_start_date_sk, 
        p.p_end_date_sk
    FROM 
        promotion p
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
        AND p.p_end_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_age AS customer_age, 
        ca.ca_city, 
        SUM(ws_ext_sales_price) AS total_web_sales, 
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year <= (YEAR(CURRENT_DATE) - 18) -- Only adult customers
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_age, ca.ca_city
)
SELECT 
    ci.customer_age, 
    ci.ca_city, 
    ci.cd_gender, 
    SUM(ci.total_web_sales) AS total_sales, 
    COUNT(*) AS customer_count, 
    MAX(lp.p_promo_name) AS max_promo_name
FROM 
    customer_info ci
LEFT JOIN 
    latest_promotions lp ON ci.total_web_sales > 1000
GROUP BY 
    ci.customer_age, ci.ca_city, ci.cd_gender
HAVING 
    COUNT(*) > 5
ORDER BY 
    total_sales DESC 
LIMIT 10;
