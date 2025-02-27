
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
IncomeBandDistribution AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 5000 AND 20000 THEN 'Medium'
            ELSE 'High'
        END AS income_band
    FROM customer_demographics
)
SELECT 
    c.c_customer_id,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(sd.total_sold_quantity, 0) AS total_sold_quantity,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(sd.total_net_paid, 0) AS total_net_paid,
    ib.income_band
FROM customer c
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN IncomeBandDistribution ib ON c.c_current_cdemo_sk = ib.cd_demo_sk
WHERE (cr.total_returned_quantity IS NULL OR cr.total_returned_quantity < 5)
    AND (sd.total_sold_quantity BETWEEN 1 AND 100)
UNION 
SELECT 
    NULL AS c_customer_id,
    SUM(total_returned_quantity) AS total_returned_quantity,
    SUM(total_sold_quantity) AS total_sold_quantity,
    SUM(total_returned_amount) AS total_returned_amount,
    SUM(total_net_paid) AS total_net_paid,
    'Total' AS income_band
FROM (
    SELECT 
        cr.total_returned_quantity,
        sd.total_sold_quantity,
        cr.total_returned_amount,
        sd.total_net_paid
    FROM CustomerReturns cr
    FULL OUTER JOIN SalesData sd ON cr.returning_customer_sk = sd.ws_bill_customer_sk
) AS combined_data
WHERE total_sold_quantity IS NOT NULL
ORDER BY total_net_paid DESC;
