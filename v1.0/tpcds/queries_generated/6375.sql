
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    WHERE 
        cs.total_sales > 1000
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.total_orders,
    hvc.avg_order_value,
    hvc.cd_gender,
    hvc.cd_marital_status,
    a.ca_city,
    a.ca_state,
    a.ca_country
FROM 
    HighValueCustomers hvc
JOIN 
    customer_address a ON hvc.c_customer_id = a.ca_address_id
ORDER BY 
    hvc.total_sales DESC
LIMIT 100;
