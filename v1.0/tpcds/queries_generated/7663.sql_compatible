
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), TopCustomers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.PurchaseRank <= 5
), 
SalesSummary AS (
    SELECT 
        ws.ws_customer_sk,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        COUNT(ws.ws_order_number) AS TotalOrders
    FROM 
        web_sales ws
    JOIN 
        TopCustomers tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
    GROUP BY 
        ws.ws_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    ss.TotalSales,
    ss.TotalOrders
FROM 
    TopCustomers tc
JOIN 
    SalesSummary ss ON tc.c_customer_sk = ss.ws_customer_sk
ORDER BY 
    ss.TotalSales DESC;
