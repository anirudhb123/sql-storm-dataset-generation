
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 5
),
SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20221231
    GROUP BY 
        ws.web_site_sk
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(cr_return_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SalesSummary ss ON ss.web_site_sk = tc.c_customer_sk
    LEFT JOIN 
        CustomerReturns cr ON cr.cr_returning_customer_sk = tc.c_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 0 AND total_returns > 0 THEN (total_returned_amount / total_sales) * 100
        ELSE NULL 
    END AS return_rate,
    CASE 
        WHEN cd_gender IS NULL THEN 'Unknown Gender'
        ELSE cd_gender 
    END AS customer_gender
FROM 
    FinalReport
WHERE 
    total_sales > 1000 OR (total_returns > 10 AND total_returned_amount > 50)
ORDER BY 
    return_rate DESC NULLS LAST;
