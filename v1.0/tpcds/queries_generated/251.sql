
WITH CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk AS customer_id,
        SUM(wr.return_quantity) AS total_returned_quantity,
        SUM(wr.return_amt) AS total_return_amount,
        COUNT(DISTINCT wr.return_order_number) AS return_count
    FROM web_returns wr
    WHERE wr.returned_date_sk >= (
        SELECT MAX(d_date_sk) - 30 FROM date_dim
    )
    GROUP BY wr.returning_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.customer_id,
        cr.total_returned_quantity,
        cr.total_return_amount,
        DENSE_RANK() OVER (ORDER BY cr.total_return_amount DESC) AS rnk
    FROM CustomerReturns cr
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
WarehouseReturns AS (
    SELECT 
        wr.refunded_customer_sk AS customer_id,
        wr.return_quantity,
        w.warehouse_name,
        COUNT(DISTINCT wr.return_order_number) AS distinct_returns
    FROM web_returns wr
    LEFT JOIN warehouse w ON wr.warehouse_sk = w.warehouse_sk
    GROUP BY wr.refunded_customer_sk, w.warehouse_name
)
SELECT 
    tc.customer_id,
    tc.total_returned_quantity,
    tc.total_return_amount,
    COALESCE(s.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
    wr.warehouse_name AS return_warehouse,
    wr.distinct_returns AS total_warehouse_returns,
    CASE 
        WHEN tc.total_return_amount > 1000 THEN 'High'
        WHEN tc.total_return_amount BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_category
FROM TopCustomers tc
LEFT JOIN SalesInfo s ON tc.customer_id = s.customer_id
LEFT JOIN WarehouseReturns wr ON tc.customer_id = wr.customer_id
WHERE tc.rnk <= 10
ORDER BY tc.total_return_amount DESC, total_quantity_sold DESC;
