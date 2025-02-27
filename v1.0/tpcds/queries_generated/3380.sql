
WITH RankedSales AS (
    SELECT
        ws.warehouse_sk,
        ws.sold_date_sk,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.net_paid) AS total_net_revenue,
        DENSE_RANK() OVER (PARTITION BY ws.warehouse_sk ORDER BY SUM(ws.net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND
          cd.cd_marital_status = 'M' AND
          cd.cd_purchase_estimate > 1000
    GROUP BY ws.warehouse_sk, ws.sold_date_sk
),
WarehouseInfo AS (
    SELECT
        w.warehouse_sk,
        w.warehouse_name,
        COALESCE(SUM(ws.total_net_revenue), 0) AS total_revenue
    FROM warehouse w
    LEFT JOIN RankedSales ws ON w.warehouse_sk = ws.warehouse_sk
    GROUP BY w.warehouse_sk, w.warehouse_name
)
SELECT
    w.warehouse_name,
    w.total_revenue,
    CASE 
        WHEN w.total_revenue > 10000 THEN 'High Revenue'
        WHEN w.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    (SELECT COUNT(*)
     FROM customer c
     WHERE c.c_current_cdemo_sk IS NOT NULL) AS total_customers,
    (SELECT COUNT(*)
     FROM inventory i
     WHERE i.inv_quantity_on_hand > 0
        AND EXISTS (
            SELECT 1
            FROM item itm
            WHERE itm.i_item_sk = i.inv_item_sk
            AND itm.i_current_price IS NOT NULL
        )) AS available_items
FROM WarehouseInfo w
WHERE w.total_revenue > (SELECT AVG(total_revenue) FROM WarehouseInfo) 
ORDER BY w.total_revenue DESC
LIMIT 10;
