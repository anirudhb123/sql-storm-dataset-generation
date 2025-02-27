
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        DENSE_RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.total_returns
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.return_rank = 1
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10
        )
    GROUP BY 
        ws_bill_customer_sk
),
FinalAnalysis AS (
    SELECT 
        hrc.c_customer_id,
        hrc.cd_gender,
        hrc.cd_marital_status,
        sd.total_sales,
        COALESCE(sd.total_sales, 0) AS adjusted_sales
    FROM 
        HighReturnCustomers hrc
    LEFT JOIN 
        SalesData sd ON hrc.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    fa.c_customer_id,
    fa.cd_gender,
    fa.cd_marital_status,
    fa.total_sales,
    CASE 
        WHEN fa.adjusted_sales IS NULL THEN 'No Sales'
        WHEN fa.adjusted_sales > 1000 THEN 'High Value Customer'
        WHEN fa.adjusted_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value,
    ROW_NUMBER() OVER (PARTITION BY fa.cd_gender ORDER BY fa.total_sales DESC) AS customer_rank
FROM 
    FinalAnalysis fa
WHERE 
    fa.total_sales IS NOT NULL
ORDER BY 
    fa.total_sales DESC, fa.cd_gender;
