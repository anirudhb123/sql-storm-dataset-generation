
WITH enriched_customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country, 
        ca.ca_zip, 
        DATE_FORMAT(DATE(CONCAT(c.c_birth_year, '-', c.c_birth_month, '-', c.c_birth_day)), '%Y-%m-%d') AS birth_date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_ext_sales_price) AS total_sales 
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
promotional_sales AS (
    SELECT  
        p.p_promo_id, 
        SUM(cs.cs_ext_sales_price) AS total_promo_sales
    FROM 
        catalog_sales cs
    JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    ei.full_name, 
    ei.ca_city, 
    ei.ca_state,
    ei.ca_country, 
    ei.ca_zip, 
    is.total_quantity_sold, 
    is.total_sales, 
    ps.total_promo_sales 
FROM 
    enriched_customer_info ei
LEFT JOIN 
    item_sales is ON ei.c_customer_sk = (SELECT MAX(c.c_customer_sk) FROM customer c JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk WHERE ws.ws_item_sk IS NOT NULL)
LEFT JOIN 
    promotional_sales ps ON ps.total_promo_sales > 0
WHERE 
    ei.cd_gender = 'F' 
    AND ei.cd_marital_status = 'S'
ORDER BY 
    is.total_sales DESC
LIMIT 100;
