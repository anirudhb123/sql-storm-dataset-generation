
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_id, 
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_items,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        AVG(sr_return_amt) AS avg_return_amount,
        SUM(COALESCE(sr_return_net_loss, 0)) AS total_net_loss
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.total_returned_items,
        cr.total_returns,
        cr.avg_return_amount,
        cr.total_net_loss,
        DENSE_RANK() OVER (ORDER BY cr.total_returned_items DESC) AS rank
    FROM CustomerReturnStats cr
    JOIN customer c ON c.c_customer_id = cr.c_customer_id
    WHERE cr.total_returns > 0
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discounts
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.total_returned_items,
    tc.total_returns,
    tc.avg_return_amount,
    tc.total_net_loss,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_discounts, 0) AS total_discounts,
    (COALESCE(sd.total_sales, 0) - COALESCE(sd.total_discounts, 0)) AS net_sales_after_discounts
FROM TopCustomers tc
LEFT JOIN SalesData sd ON tc.c_customer_id = sd.ws_bill_customer_sk
WHERE tc.rank <= 10
ORDER BY tc.rank;
