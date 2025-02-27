
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
    FROM 
        CustomerData c
    WHERE 
        c.rn <= 10
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.cd_gender, 
    tc.cd_marital_status, 
    ss.total_sales,
    ss.total_orders,
    ss.avg_net_paid
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesSummary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    (ss.total_sales IS NULL OR ss.total_sales > 1000) 
    AND (tc.cd_marital_status = 'M' OR tc.cd_marital_status IS NULL)
ORDER BY 
    total_sales DESC;
