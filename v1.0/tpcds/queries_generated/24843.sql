
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        DENSE_RANK() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM store_returns
    GROUP BY sr_returning_customer_sk
), 
HighReturnCustomers AS (
    SELECT 
        rr.returning_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(cd.cd_credit_rating, 'No Rating') AS credit_rating,
        rr.total_returned,
        rr.return_count
    FROM RankedReturns rr
    JOIN customer c ON rr.returning_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE rr.rank = 1
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_net_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    hrc.c_first_name,
    hrc.c_last_name,
    hrc.c_email_address,
    hrc.gender,
    hrc.marital_status,
    hrc.credit_rating,
    hrc.total_returned,
    hrc.return_count,
    ss.total_profit,
    ss.order_count,
    ss.avg_net_paid
FROM HighReturnCustomers hrc
LEFT JOIN SalesSummary ss ON hrc.returning_customer_sk = ss.ws_bill_customer_sk
WHERE hrc.total_returned > (SELECT AVG(total_returned) FROM RankedReturns)
    AND (ss.total_profit IS NULL OR ss.order_count > 5)
ORDER BY hrc.total_returned DESC,
         hrc.c_last_name ASC;
