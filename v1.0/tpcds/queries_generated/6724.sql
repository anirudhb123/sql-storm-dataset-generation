
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cp.total_web_sales, 
        cp.order_count
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_sk = c.c_customer_sk
    WHERE 
        cp.total_web_sales > 0
    ORDER BY 
        cp.total_web_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_income_band_sk
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M'
ORDER BY 
    tc.total_web_sales DESC;
