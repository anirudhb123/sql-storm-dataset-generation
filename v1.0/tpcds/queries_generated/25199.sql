
WITH Customer_Info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Sales_Stats AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Result AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.cd_gender,
        ci.cd_marital_status,
        ss.total_orders,
        ss.total_sales,
        ss.total_net_profit
    FROM 
        Customer_Info ci
    LEFT JOIN 
        Sales_Stats ss ON ci.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    cd_marital_status,
    total_orders,
    total_sales,
    total_net_profit,
    CASE 
        WHEN total_sales > 10000 THEN 'High Spender'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category,
    CONCAT('Customer in ', ca_city, ', ', ca_state) AS location_desc
FROM 
    Result
WHERE 
    ca_country = 'USA'
ORDER BY 
    total_sales DESC
LIMIT 50;
