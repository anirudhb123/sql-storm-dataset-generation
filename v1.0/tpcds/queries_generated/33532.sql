
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk AS customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_returned_amt,
        CASE 
            WHEN SUM(sr_return_quantity) > 10 THEN 'High Return'
            WHEN SUM(sr_return_quantity) BETWEEN 5 AND 10 THEN 'Medium Return'
            ELSE 'Low Return'
        END AS return_category
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDemographic AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state
    FROM customer_address ca
)
SELECT 
    CD.c_customer_sk,
    CD.cd_gender,
    CD.cd_marital_status,
    COALESCE(CR.total_returned, 0) AS total_returned,
    COALESCE(SS.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(SS.total_net_profit, 0) AS total_net_profit,
    A.ca_city,
    A.ca_state,
    CASE 
        WHEN COALESCE(CR.total_returned, 0) > 10 THEN 'High Risk'
        WHEN COALESCE(SS.total_net_profit, 0) < 500 THEN 'Low Profit'
        ELSE 'Stable'
    END AS customer_status
FROM CustomerDemographic CD
LEFT JOIN CustomerReturns CR ON CD.c_customer_sk = CR.customer_sk
LEFT JOIN SalesSummary SS ON CD.c_customer_sk = SS.customer_sk
LEFT JOIN AddressInfo A ON CD.c_customer_sk = A.ca_address_sk
WHERE CD.cd_gender = 'F'
  AND (CD.cd_marital_status = 'M' OR CD.cd_marital_status IS NULL)
ORDER BY customer_status, total_net_profit DESC
FETCH FIRST 100 ROWS ONLY;
