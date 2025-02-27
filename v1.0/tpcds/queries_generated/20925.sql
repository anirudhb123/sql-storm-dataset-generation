
WITH RecursiveCustomerReturns AS (
    SELECT sr_customer_sk, COUNT(sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
TotalReturns AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(r.total_returns, 0) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) OVER (PARTITION BY r.total_returns ORDER BY c.c_customer_id) AS tier
    FROM customer c
    LEFT JOIN RecursiveCustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
),
WarehouseAverage AS (
    SELECT 
        w.w_warehouse_id,
        AVG(w.w_warehouse_sq_ft) AS avg_sq_ft
    FROM warehouse w
    WHERE w.w_warehouse_sq_ft IS NOT NULL
    GROUP BY w.w_warehouse_id
),
ItemSales AS (
    SELECT 
        i.i_item_id,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_sold,
        SUM(COALESCE(ws.ws_sales_price, 0) * COALESCE(ws.ws_quantity, 0)) AS total_revenue
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tr.total_returns,
    wa.w_warehouse_id,
    ia.i_item_id,
    ia.total_sold,
    ia.total_revenue,
    CASE
        WHEN tr.tier = 0 THEN 'New Customer'
        WHEN tr.tier BETWEEN 1 AND 5 THEN 'Frequent Customer'
        ELSE 'VIP Customer'
    END AS customer_tier,
    CASE
        WHEN wa.avg_sq_ft IS NULL THEN 'Data Not Available'
        ELSE 'Average Sq Ft: ' || ROUND(wa.avg_sq_ft, 2)
    END AS warehouse_info
FROM TotalReturns tr
JOIN WarehouseAverage wa ON tr.total_returns > 0
JOIN ItemSales ia ON ia.total_revenue > 1000
JOIN customer c ON tr.c_customer_id = c.c_customer_id
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE (tr.total_returns = 0 OR wa.w_warehouse_id IS NULL)
  AND EXISTS (
      SELECT 1
      FROM inventory i
      WHERE i.inv_quantity_on_hand > 0
      AND i.inv_item_sk IN (
          SELECT i.i_item_sk
          FROM item i
          WHERE i.i_item_id = ia.i_item_id
      )
  )
ORDER BY tr.total_returns DESC, c.c_first_name, c.c_last_name;
