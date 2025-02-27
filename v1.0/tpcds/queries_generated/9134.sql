
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        sd.total_profit,
        sd.avg_sales_price,
        sd.total_orders,
        cd.education_status,
        cd.gender
    FROM 
        sales_data sd
    JOIN 
        customer c ON sd.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        sd.total_profit > (SELECT AVG(total_profit) FROM sales_data)
    ORDER BY 
        sd.total_profit DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_id,
    tc.total_profit,
    tc.avg_sales_price,
    tc.total_orders,
    tc.education_status,
    tc.gender,
    ca.ca_city,
    ca.ca_state
FROM 
    top_customers tc
JOIN 
    customer_address ca ON tc.ws_bill_customer_sk = ca.ca_address_sk
ORDER BY 
    tc.total_profit DESC;
