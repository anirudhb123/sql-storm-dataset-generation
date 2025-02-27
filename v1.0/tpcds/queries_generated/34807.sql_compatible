
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 5000 
        AND cd.cd_gender = 'M'
),
FinalReport AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        COALESCE(s.total_sales, 0) AS total_sales,
        hvc.total_returns,
        hvc.total_return_amount,
        CASE 
            WHEN hvc.total_return_amount > 1000 THEN 'High Return'
            ELSE 'Regular Return'
        END AS return_category
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        SalesCTE s ON hvc.c_customer_sk = s.web_site_sk
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    return_category = 'High Return'
ORDER BY 
    total_sales DESC, total_return_amount DESC
LIMIT 10;
