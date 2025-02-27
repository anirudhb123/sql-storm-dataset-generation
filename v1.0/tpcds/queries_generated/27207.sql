
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM 
        item i
),
sales_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
benchmark_results AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        ii.i_product_name,
        ii.i_brand,
        ii.i_category,
        si.total_quantity,
        si.total_sales,
        CASE 
            WHEN si.total_sales IS NULL THEN 0 
            ELSE (si.total_sales / NULLIF(si.total_quantity, 0)) 
        END AS avg_sales_price
    FROM 
        customer_info ci
    JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    JOIN 
        item_info ii ON si.ws_item_sk = ii.i_item_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cr.c_customer_sk) AS unique_customers,
    AVG(cr.avg_sales_price) AS average_sales_price
FROM 
    benchmark_results cr
JOIN 
    customer_address ca ON cr.c_customer_sk = ca.ca_address_sk  
WHERE 
    cr.ca_state = 'CA'
GROUP BY 
    ca.ca_city
ORDER BY 
    unique_customers DESC, average_sales_price DESC
LIMIT 10;
