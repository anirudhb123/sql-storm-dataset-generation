
WITH CustomerRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
ReturnsData AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returns,
        COUNT(wr_return_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CustomerSalesReturns AS (
    SELECT 
        cr.c_customer_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        cr.rank_gender
    FROM 
        CustomerRanked cr
    LEFT JOIN 
        SalesData sd ON cr.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN 
        ReturnsData rd ON cr.c_customer_sk = rd.wr_returning_customer_sk
)
SELECT 
    csr.c_customer_sk,
    csr.total_sales,
    csr.total_returns,
    csr.rank_gender,
    CASE 
        WHEN csr.total_sales > 1000 AND csr.rank_gender = 1 THEN 'High Value Female Customer'
        WHEN csr.total_sales > 1000 AND csr.rank_gender = 2 THEN 'High Value Male Customer'
        ELSE 'Standard Customer'
    END AS customer_segment
FROM 
    CustomerSalesReturns csr
ORDER BY 
    csr.total_sales DESC
LIMIT 100;
