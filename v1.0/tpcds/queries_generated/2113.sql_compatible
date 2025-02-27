
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_ship_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank_per_order
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregatedReturns AS (
    SELECT 
        cr.cr_returning_customer_sk,
        SUM(cr.cr_return_amount) AS total_returned,
        COUNT(cr.cr_order_number) AS return_count
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk IN 
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY cr.cr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        COALESCE(ar.total_returned, 0) AS total_returned,
        COALESCE(ar.return_count, 0) AS return_count
    FROM customer c
    LEFT JOIN AggregatedReturns ar ON c.c_customer_sk = ar.cr_returning_customer_sk
    WHERE COALESCE(ar.total_returned, 0) > 0
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COUNT(rs.ws_item_sk) AS items_ordered,
    SUM(rs.ws_sales_price) AS total_spent,
    AVG(rs.ws_sales_price) AS avg_spent_per_item
FROM TopCustomers tc
JOIN RankedSales rs ON tc.c_customer_sk = rs.ws_bill_customer_sk
WHERE rs.rank_per_order = 1
GROUP BY tc.c_customer_sk, tc.c_first_name, tc.c_last_name
HAVING SUM(rs.ws_sales_price) > 100
ORDER BY total_spent DESC;
