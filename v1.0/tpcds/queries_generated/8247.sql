
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    JOIN 
        customer c ON rc.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        rc.rnk <= 10
),
SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    sd.total_spent,
    sd.total_orders
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesData sd ON tc.c_customer_id = sd.bill_customer_sk
ORDER BY 
    sd.total_spent DESC
LIMIT 50;
