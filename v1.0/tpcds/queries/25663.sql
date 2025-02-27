
WITH CustomerAnalytics AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        AVG(ws.ws_ext_sales_price) AS average_spent,
        STRING_AGG(DISTINCT wp.wp_url, '; ') AS visited_websites
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        SUM(total_orders) AS total_orders,
        SUM(total_spent) AS total_spent,
        AVG(average_spent) AS average_spent
    FROM 
        CustomerAnalytics
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    customer_count,
    total_orders,
    total_spent,
    average_spent,
    CASE 
        WHEN average_spent > 1000 THEN 'High Spender'
        WHEN average_spent BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    DemographicSummary
ORDER BY 
    total_spent DESC;
