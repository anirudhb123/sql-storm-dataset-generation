
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        ws.bill_customer_sk
),
TopCustomers AS (
    SELECT 
        r.bill_customer_sk,
        r.total_quantity,
        r.total_sales,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        RankedSales r
    JOIN 
        customer_demographics cd ON r.bill_customer_sk = cd.cd_demo_sk
    WHERE 
        r.sales_rank <= 10
),
SalesReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_qty) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    tc.bill_customer_sk,
    tc.total_quantity,
    tc.total_sales,
    COALESCE(sr.total_returns, 0) AS total_returns,
    (tc.total_sales - COALESCE(sr.total_returns, 0)) AS net_sales,
    CASE 
        WHEN tc.cd_gender = 'M' THEN 'Male'
        WHEN tc.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_desc
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesReturns sr ON tc.bill_customer_sk = sr.sr_customer_sk
ORDER BY 
    net_sales DESC;
