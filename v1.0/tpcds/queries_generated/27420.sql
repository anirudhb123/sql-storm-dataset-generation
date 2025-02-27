
WITH aggregated_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        COUNT(ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        agg.order_count,
        agg.total_sales,
        agg.total_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        aggregated_sales agg ON c.c_customer_sk = agg.ws_bill_customer_sk
    WHERE 
        agg.total_sales > 1000 -- Filter for customers with significant sales
    ORDER BY 
        total_profit DESC
    LIMIT 10
),
customer_demographics AS (
    SELECT 
        cu.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        top_customers cu
    JOIN 
        customer_demographics cd ON cu.c_customer_id = cd.cd_demo_sk
)
SELECT 
    c.c_customer_id,
    c.ca_city,
    c.ca_state,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    t.order_count,
    t.total_sales,
    t.total_profit
FROM 
    customer_demographics d
JOIN 
    top_customers t ON d.c_customer_id = t.c_customer_id
JOIN 
    customer_address c ON t.c_customer_id = c.ca_address_id
ORDER BY 
    t.total_sales DESC, 
    t.total_profit DESC;
