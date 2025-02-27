
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), sales_summary AS (
    SELECT 
        cs.cs_bill_customer_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        AVG(cs.cs_sales_price) AS average_sales_price
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_bill_customer_sk
), aggregated_data AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        s.total_profit,
        s.order_count,
        s.average_sales_price,
        CASE 
            WHEN s.order_count >= 5 THEN 'Frequent Buyer'
            WHEN s.order_count BETWEEN 1 AND 4 THEN 'Occasional Buyer'
            ELSE 'No Purchases'
        END AS purchase_category
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary s ON ci.c_customer_sk = s.cs_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_profit,
    order_count,
    average_sales_price,
    purchase_category,
    CASE 
        WHEN email_length > 30 THEN 'Long Email'
        WHEN email_length BETWEEN 20 AND 30 THEN 'Medium Email'
        ELSE 'Short Email'
    END AS email_category
FROM 
    aggregated_data
ORDER BY 
    total_profit DESC, 
    order_count DESC;
