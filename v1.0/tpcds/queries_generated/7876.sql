
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_sk, c.c_gender
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value,
        CASE 
            WHEN cs.total_sales > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    hvc.customer_type,
    hvc.c_gender,
    COUNT(*) AS num_customers,
    AVG(hvc.total_sales) AS avg_sales,
    AVG(hvc.total_orders) AS avg_orders,
    MAX(hvc.avg_order_value) AS max_avg_order_value
FROM 
    HighValueCustomers hvc
GROUP BY 
    hvc.customer_type, hvc.c_gender
ORDER BY 
    hvc.customer_type DESC, hvc.c_gender;
