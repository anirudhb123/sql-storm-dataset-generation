
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cp.total_sales,
        cp.order_count,
        cp.avg_net_paid
    FROM 
        CustomerPurchases cp
    JOIN 
        customer_demographics cd ON cp.c_customer_id = cd.cd_demo_sk
    WHERE 
        cp.total_sales > 1000 AND cd.cd_credit_rating = 'Excellent'
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    hvc.avg_net_paid
FROM 
    HighValueCustomers hvc
JOIN 
    customer c ON hvc.c_customer_id = c.c_customer_id
ORDER BY 
    hvc.total_sales DESC
LIMIT 10;
