
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        COALESCE(cd.cd_dep_count, 0) AS total_dependents
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    sd.ws_item_sk,
    cs.c_customer_sk,
    SUM(cs.total_sales) AS total_sales_per_customer,
    MAX(cs.total_quantity) AS max_quantity_bought,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    CASE 
        WHEN SUM(cs.total_sales) > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    sales_summary cs
JOIN 
    customer_data cd ON cs.ws_item_sk = cd.c_customer_sk
JOIN 
    date_dim dd ON dd.d_date_sk = cs.ws_sold_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    sd.ws_item_sk, cs.c_customer_sk
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_sales_per_customer DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
