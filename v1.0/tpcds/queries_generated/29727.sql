
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        RankedCustomers
    WHERE 
        rank <= 10
),
SalesSummary AS (
    SELECT 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ws.ws_bill_cdemo_sk AS customer_demo_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_cdemo_sk
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    ss.total_sales,
    ss.order_count
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesSummary ss ON ss.customer_demo_sk = (
        SELECT cd.cd_demo_sk
        FROM customer_demographics cd 
        JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
        WHERE CONCAT(c.c_first_name, ' ', c.c_last_name) = tc.full_name
    )
ORDER BY 
    ss.total_sales DESC NULLS LAST;
