
WITH EnhancedCustomer AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        LEAST(cd.cd_purchase_estimate, 1000) AS purchase_estimate,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_description
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ec.ca_city,
        ec.ca_state,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        EnhancedCustomer ec
    JOIN 
        web_sales ws ON ec.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        ec.ca_city, ec.ca_state
)
SELECT 
    es.ca_city,
    es.ca_state,
    es.total_sales,
    es.total_orders,
    es.avg_sales_price,
    RANK() OVER (PARTITION BY es.ca_state ORDER BY es.total_sales DESC) AS sales_rank
FROM 
    SalesSummary es
WHERE 
    es.total_sales > 0
ORDER BY 
    es.ca_state, sales_rank;
