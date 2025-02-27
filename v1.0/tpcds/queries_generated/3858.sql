
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
PopularItems AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > (
        SELECT AVG(cd_purchase_estimate) 
        FROM customer_demographics
    )
),
AggregateReturns AS (
    SELECT 
        cr.sr_customer_sk, 
        SUM(cr.total_return_amount) AS total_returned_value
    FROM CustomerReturns cr
    JOIN HighValueCustomers hvc ON cr.sr_customer_sk = hvc.c_customer_sk
    GROUP BY cr.sr_customer_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    COALESCE(ar.total_returned_value, 0) AS total_returned_value,
    pi.total_sales AS total_sales_of_frequent_items
FROM HighValueCustomers hvc
LEFT JOIN AggregateReturns ar ON hvc.c_customer_sk = ar.sr_customer_sk
LEFT JOIN PopularItems pi ON pi.ws_item_sk IN (
    SELECT sr_item_sk FROM store_sales WHERE ss_customer_sk = hvc.c_customer_sk
)
ORDER BY total_returned_value DESC, total_sales_of_frequent_items DESC;
