
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rn
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
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    COALESCE(im.total_sold, 0) AS total_items_sold,
    COALESCE(im.total_revenue, 0) AS total_revenue,
    ms.total_quantity_sold,
    ms.total_sales
FROM 
    customer_info ci
LEFT JOIN 
    item_sales im ON ci.c_customer_id = im.ws_item_sk
LEFT JOIN 
    monthly_sales ms ON EXTRACT(YEAR FROM CURRENT_DATE) = ms.d_year
WHERE 
    ci.rn = 1
ORDER BY 
    ci.full_name;
