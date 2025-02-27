
WITH CustomerReturns AS (
    SELECT 
        sr_sr_customer_sk AS customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
RecentSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales_amt,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_bill_customer_sk
),
ActiveCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
),
SalesAndReturns AS (
    SELECT 
        COALESCE(s.customer_sk, r.customer_sk) AS customer_sk,
        COALESCE(s.total_sales_amt, 0) AS total_sales_amt,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_return_amt, 0) AS total_return_amt
    FROM 
        RecentSales s
    FULL OUTER JOIN 
        CustomerReturns r ON s.customer_sk = r.customer_sk
),
FinalResults AS (
    SELECT 
        ac.c_customer_sk,
        ac.c_first_name,
        ac.c_last_name,
        ac.cd_gender,
        ac.cd_marital_status,
        ac.cd_purchase_estimate,
        sar.total_sales_amt,
        sar.total_return_quantity,
        sar.total_return_amt,
        (sar.total_sales_amt - sar.total_return_amt) AS net_sales
    FROM 
        ActiveCustomers ac
        LEFT JOIN SalesAndReturns sar ON ac.c_customer_sk = sar.customer_sk
)

SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_purchase_estimate,
    fr.total_sales_amt,
    fr.total_return_quantity,
    fr.total_return_amt,
    fr.net_sales,
    CASE 
        WHEN fr.net_sales < 0 THEN 'Loss' 
        ELSE 'Profit' 
    END AS sales_status
FROM 
    FinalResults fr
WHERE 
    fr.cd_purchase_estimate IS NOT NULL
ORDER BY 
    fr.net_sales DESC
LIMIT 100;
