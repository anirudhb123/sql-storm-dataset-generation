
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        ws_item_sk AS item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ci.total_quantity,
        ci.total_sales,
        ci.total_profit,
        ci.order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        sales_data ci ON c.c_customer_sk = ci.customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(c.total_sales) AS overall_sales,
        SUM(c.total_profit) AS overall_profit,
        COUNT(DISTINCT c.order_count) AS unique_items_sold
    FROM 
        customer_info c
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        overall_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_id,
    tc.overall_sales,
    tc.overall_profit,
    tc.unique_items_sold,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_education_status
FROM 
    top_customers tc
JOIN 
    customer_info ci ON tc.c_customer_id = ci.c_customer_id
JOIN 
    customer_demographics sd ON ci.cd_gender = sd.cd_gender
ORDER BY 
    tc.overall_sales DESC;
