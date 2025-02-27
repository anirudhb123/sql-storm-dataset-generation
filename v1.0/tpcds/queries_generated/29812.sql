
WITH customer_details AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate,
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country, 
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
customer_interactions AS (
    SELECT 
        customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_web_orders,
        COUNT(DISTINCT ss_ticket_number) AS total_store_sales
    FROM 
        (
            SELECT ws_bill_customer_sk AS customer_sk, ws_order_number FROM web_sales
            UNION ALL
            SELECT ss_customer_sk AS customer_sk, ss_ticket_number FROM store_sales
        ) AS combined_sales
    GROUP BY customer_sk
),
customer_analysis AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ci.total_web_orders,
        ci.total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ci.total_web_orders DESC) AS web_order_rank,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY ci.total_store_sales DESC) AS store_sales_rank
    FROM 
        customer_details cd
    LEFT JOIN 
        customer_interactions ci ON cd.c_customer_id = ci.customer_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name, 
    c.cd_gender, 
    c.cd_marital_status, 
    c.total_web_orders, 
    c.total_store_sales,
    c.web_order_rank,
    c.store_sales_rank
FROM 
    customer_analysis c
WHERE 
    c.web_order_rank <= 10 
    OR c.store_sales_rank <= 10
ORDER BY 
    c.cd_gender, 
    c.cd_marital_status, 
    c.total_web_orders DESC, 
    c.total_store_sales DESC;
