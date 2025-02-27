
WITH BestSellingItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(crs.total_returns, 0) AS return_count,
        COALESCE(crs.total_return_amt, 0) AS total_return_amount
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturnStats crs ON c.c_customer_sk = crs.sr_customer_sk
    WHERE cd.cd_purchase_estimate > 1000
),
ItemWarehouseStats AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_available
    FROM item i
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    bsi.total_quantity AS total_items_sold,
    iws.warehouse_count,
    iws.total_quantity_available,
    CASE 
        WHEN hvc.total_return_amount > 100 THEN 'High Returning Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM HighValueCustomers hvc
LEFT JOIN BestSellingItems bsi ON hvc.c_customer_sk IN (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk IN (SELECT ws_item_sk FROM BestSellingItems WHERE rank <= 10)
)
LEFT JOIN ItemWarehouseStats iws ON bsi.ws_item_sk = iws.i_item_sk
ORDER BY hvc.cd_purchase_estimate DESC, total_items_sold DESC;
