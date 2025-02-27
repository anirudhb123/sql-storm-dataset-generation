
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value
    FROM 
        CustomerSales cs
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
),
SalesComparison AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value,
        CASE 
            WHEN cs.total_sales > 5000 THEN 'High Value'
            WHEN cs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        TopCustomers cs
)
SELECT 
    t.c_customer_id,
    t.total_sales,
    t.total_orders,
    t.avg_order_value,
    t.customer_value_segment,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city,
    ca.ca_state,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_additional_spending
FROM 
    SalesComparison t
LEFT JOIN 
    customer_demographics cd ON t.c_customer_id = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON t.c_customer_id = ws.ws_ship_customer_sk
GROUP BY 
    t.c_customer_id, t.total_sales, t.total_orders, t.avg_order_value, 
    t.customer_value_segment, cd.cd_gender, cd.cd_marital_status, 
    ca.ca_city, ca.ca_state
ORDER BY 
    t.total_sales DESC;
