
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(cr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT cr_order_number) AS catalog_return_count,
        COUNT(DISTINCT wr_order_number) AS web_return_count
    FROM 
        customer AS c
    LEFT JOIN store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns AS cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns AS wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    WHERE 
        c.c_current_cdemo_sk IN (
            SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M'
        )
    GROUP BY c.c_customer_id
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws_bill_customer_sk
)

SELECT 
    cr.c_customer_id,
    cr.total_returns,
    sd.total_profit,
    sd.order_count,
    CASE 
        WHEN cr.total_returns > 1 THEN 'High Return Customer'
        WHEN cr.total_returns = 1 THEN 'Moderate Return Customer'
        ELSE 'Low Return Customer'
    END AS return_customer_category
FROM 
    CustomerReturns cr
FULL OUTER JOIN SalesData sd ON cr.c_customer_id = (
    SELECT c_customer_id FROM customer WHERE c_customer_sk = sd.customer_sk
)
WHERE 
    (cr.total_returns IS NOT NULL OR sd.total_profit IS NOT NULL)
ORDER BY sd.total_profit DESC NULLS LAST;
