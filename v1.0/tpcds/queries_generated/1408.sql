
WITH RankedSales AS (
    SELECT
        s_store_sk,
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    JOIN store s ON ws.ws_store_sk = s.s_store_sk
    WHERE ws_sold_date_sk BETWEEN 1 AND 365
),
CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_id,
        cd.cd_marital_status,
        cr.total_return_amount
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    WHERE cd.cd_purchase_estimate > 5000
)
SELECT
    hs.s_store_id,
    COUNT(DISTINCT r.cs_order_number) AS total_orders,
    SUM(COALESCE(hvc.total_return_amount, 0)) AS total_returned_amount,
    AVG(DISTINCT ws.ws_sales_price) AS avg_sales_price
FROM RankedSales rs
JOIN store_sales r ON rs.ws_order_number = r.ss_ticket_number AND rs.ws_item_sk = r.ss_item_sk
JOIN HighValueCustomers hvc ON hvc.c_customer_id = r.ss_customer_sk
JOIN store s ON r.ss_store_sk = s.s_store_sk
LEFT JOIN warehouse w ON s.s_store_sk = w.w_warehouse_sk
WHERE rs.sales_rank <= 10
  AND hvc.total_return_amount IS NOT NULL
GROUP BY hs.s_store_id
HAVING total_orders > 100
ORDER BY total_returned_amount DESC;
