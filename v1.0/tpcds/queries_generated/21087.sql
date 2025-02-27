
WITH RecursiveReturns AS (
    SELECT 
        wr_refunded_customer_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM web_returns
    GROUP BY wr_refunded_customer_sk, wr_item_sk
), 
RichCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(web_sales.ws_net_paid) AS total_spent,
        CASE 
            WHEN COUNT(DISTINCT ws_order_number) > 10 THEN 'Frequent Buyer'
            ELSE 'Occasional Buyer' 
        END AS buyer_type
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ON c.c_customer_sk = ws_ship_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender
    HAVING SUM(web_sales.ws_net_paid) IS NOT NULL
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        SUM(CASE WHEN inv_quantity_on_hand IS NULL THEN 0 ELSE inv_quantity_on_hand END) AS total_items_in_stock,
        AVG(COALESCE(inv_quantity_on_hand, 0)) AS average_stock
    FROM warehouse w
    LEFT JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT 
    rc.c_customer_id, 
    rc.cd_gender,
    rc.total_spent,
    rc.buyer_type,
    wr.total_returned,
    wr.total_return_amount,
    ws.w_warehouse_id,
    ws.total_items_in_stock,
    ws.average_stock
FROM RichCustomers rc
LEFT JOIN RecursiveReturns wr ON rc.c_customer_id = wr.wr_refunded_customer_sk
JOIN WarehouseStats ws ON ws.total_items_in_stock > (
    SELECT AVG(total_items_in_stock) FROM WarehouseStats
)
WHERE rc.total_spent > (
    SELECT AVG(total_spent) FROM RichCustomers
) AND 
rc.buyer_type = 'Frequent Buyer'
ORDER BY rc.total_spent DESC, wr.total_returned DESC
LIMIT 100;
