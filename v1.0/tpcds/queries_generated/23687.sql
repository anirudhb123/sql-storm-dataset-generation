
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sales_price > (
        SELECT AVG(ws2.ws_sales_price) 
        FROM web_sales ws2 
        WHERE ws2.ws_order_number = ws.ws_order_number
    )
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA' AND cd.cd_purchase_estimate > 1000
),
InventoryCheck AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM item i
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk
    HAVING SUM(inv.inv_quantity_on_hand) < 10
),
ReturnsAnalysis AS (
    SELECT
        wr.wr_order_number,
        COUNT(DISTINCT wr.wr_item_sk) AS unique_items_returned,
        SUM(wr.wr_return_amt) AS total_returned
    FROM web_returns wr
    GROUP BY wr.wr_order_number
    HAVING SUM(wr.wr_return_amt) IS NOT NULL
),
FinalReport AS (
    SELECT 
        cs.c_customer_id,
        SUM(rs.ws_sales_price) AS total_spent,
        COUNT(DISTINCT rs.ws_order_number) AS order_count,
        AVG(COALESCE(inv.total_quantity, 0)) AS avg_inventory,
        ra.unique_items_returned,
        ra.total_returned
    FROM CustomerDetails cs
    JOIN RankedSales rs ON cs.c_customer_id = rs.ws_order_number
    LEFT JOIN InventoryCheck inv ON rs.ws_item_sk = inv.i_item_sk
    LEFT JOIN ReturnsAnalysis ra ON rs.ws_order_number = ra.wr_order_number
    GROUP BY cs.c_customer_id
)
SELECT 
    f.c_customer_id,
    f.total_spent,
    f.order_count,
    CASE 
        WHEN f.total_spent IS NULL THEN 'No Sales'
        WHEN f.total_spent < 500 THEN 'Low Spender'
        WHEN f.total_spent < 1000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category,
    f.avg_inventory,
    f.unique_items_returned,
    f.total_returned
FROM FinalReport f
WHERE f.total_spent IS NOT NULL
ORDER BY f.total_spent DESC
LIMIT 100;
