
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        SUM(wr_return_amount) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rn
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_buy_potential,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(sd.total_sales, 0) AS total_sales,
    sd.total_orders,
    CASE 
        WHEN sd.total_sales > 0 THEN (cr.total_return_amount / sd.total_sales) * 100 
        ELSE 0 
    END AS return_percentage
FROM CustomerDemographics cd
LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.wr_returning_customer_sk
LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk AND sd.rn = 1
WHERE 
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M')
    OR 
    (cd.cd_gender = 'M' AND cd.cd_marital_status = 'S')
ORDER BY return_percentage DESC, total_sales DESC
LIMIT 50;
