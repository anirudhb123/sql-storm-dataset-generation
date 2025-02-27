
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS num_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_return_quantity,
        cr.total_return_amt,
        cr.num_returns,
        RANK() OVER (ORDER BY cr.total_return_amt DESC) AS rank
    FROM CustomerReturns cr
    JOIN customer c ON cr.wr_returning_customer_sk = c.c_customer_sk
    WHERE cr.num_returns > 1
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        AVG(inv_quantity_on_hand) AS avg_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
SalesComparison AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discounts,
        wp.wp_access_date_sk,
        CASE 
            WHEN SUM(ws_ext_sales_price) > 10000 THEN 'High Sales'
            WHEN SUM(ws_ext_sales_price) BETWEEN 5000 AND 10000 THEN 'Medium Sales'
            ELSE 'Low Sales'
        END AS sales_category
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY w.w_warehouse_id, wp.wp_access_date_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    wc.w_warehouse_id,
    wc.avg_quantity,
    wc.total_orders,
    sc.total_sales,
    sc.total_discounts,
    sc.sales_category
FROM TopCustomers tc
LEFT JOIN WarehouseStats wc ON TRUE
FULL OUTER JOIN SalesComparison sc ON wc.w_warehouse_id = sc.w_warehouse_id
WHERE tc.rank <= 5
AND (sc.total_sales IS NOT NULL OR wc.avg_quantity IS NOT NULL)
ORDER BY tc.total_return_amt DESC, wc.total_orders DESC;
