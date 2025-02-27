
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_profit,
        ss.total_orders,
        ss.unique_items_sold
    FROM 
        customer cs
    JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.customer_sk
    WHERE 
        ss.total_profit > 1000
    ORDER BY 
        ss.total_profit DESC
    LIMIT 10
),
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
    JOIN 
        top_customers tc ON cd.cd_demo_sk = tc.customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    tc.total_profit,
    tc.total_orders,
    tc.unique_items_sold
FROM 
    top_customers tc
JOIN 
    customer_demo cd ON tc.customer_sk = cd.cd_demo_sk
ORDER BY 
    tc.total_profit DESC;
