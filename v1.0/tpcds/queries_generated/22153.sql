
WITH RankedReturns AS (
    SELECT 
        wr.returning_customer_sk,
        wr.return_quantity,
        wr.return_amt,
        RANK() OVER (PARTITION BY wr.returning_customer_sk ORDER BY wr.returned_date_sk DESC, wr.returned_time_sk DESC) AS return_rank
    FROM web_returns wr
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT wr.returning_customer_sk) AS total_returns,
        AVG(wr.return_amt) AS avg_return_amount
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN RankedReturns wr ON c.c_customer_sk = wr.returning_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_profit, 0) AS total_profit,
        cd.total_returns,
        cd.avg_return_amount
    FROM CustomerData cd
    LEFT JOIN SalesData sd ON cd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_sales,
    cd.total_profit,
    cd.total_returns,
    cd.avg_return_amount,
    CASE 
        WHEN cd.total_returns > 0 AND cd.total_sales > 0 THEN (cd.avg_return_amount / NULLIF(cd.total_sales, 0))
        ELSE NULL
    END AS return_to_sales_ratio,
    CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status) AS demographic_info
FROM CombinedData cd
WHERE cd.total_returns > 10 
AND (cd.avg_return_amount IS NOT NULL OR cd.total_profit > 1000)
ORDER BY cd.total_sales DESC, cd.total_returns DESC
LIMIT 100
OFFSET 0;
