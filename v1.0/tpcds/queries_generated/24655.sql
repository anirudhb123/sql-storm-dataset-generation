
WITH CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk, 
        COUNT(DISTINCT wr.return_number) AS return_count,
        SUM(COALESCE(wr.return_amt, 0)) AS total_return_amt,
        SUM(COALESCE(wr.return_tax, 0)) AS total_return_tax
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer_demographics cd
),
SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        SUM(ws.net_profit) AS total_profit
    FROM web_sales ws
    WHERE ws.sold_date_sk IN (SELECT DISTINCT sr.returned_date_sk FROM store_returns sr)
    GROUP BY ws.bill_customer_sk
)
SELECT 
    c.c_customer_id,
    d.return_count,
    d.total_return_amt,
    d.total_return_tax,
    s.total_sales,
    s.total_profit,
    cd.marital_status,
    cd.purchase_rank
FROM customer c
LEFT JOIN CustomerReturns d ON c.c_customer_sk = d.returning_customer_sk
LEFT JOIN SalesData s ON c.c_customer_sk = s.bill_customer_sk
LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.purchase_rank <= 10 
    AND (d.total_return_amt > 100 OR s.total_sales IS NULL)
ORDER BY 
    total_sales DESC NULLS LAST,
    return_count ASC,
    c.c_customer_id;
