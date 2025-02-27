
WITH RECURSIVE Inventory_CTE AS (
    SELECT w.warehouse_id, i.inv_item_sk, i.inv_quantity_on_hand
    FROM warehouse w
    JOIN inventory i ON w.warehouse_sk = i.inv_warehouse_sk
    WHERE i.inv_quantity_on_hand > 0

    UNION ALL

    SELECT w.warehouse_id, i.inv_item_sk, i.inv_quantity_on_hand
    FROM warehouse w
    JOIN inventory i ON w.warehouse_sk = i.inv_warehouse_sk
    JOIN Inventory_CTE ic ON ic.inv_item_sk = i.inv_item_sk
    WHERE i.inv_quantity_on_hand + ic.inv_quantity_on_hand > 0
),
Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws.ws_item_sk
),
Sales_Demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_income_band_sk
),
Top_Customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_spend
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
    ORDER BY total_spend DESC
    LIMIT 10
)
SELECT 
    ic.warehouse_id,
    s.ws_item_sk,
    s.total_sales,
    s.total_profit,
    sd.cd_gender,
    sd.cd_income_band_sk,
    tc.total_spend
FROM Inventory_CTE ic
JOIN Sales s ON ic.inv_item_sk = s.ws_item_sk
LEFT JOIN Sales_Demographics sd ON sd.c_customer_sk IN (SELECT c.c_customer_sk FROM Top_Customers tc)
JOIN Top_Customers tc ON sd.c_customer_sk = tc.c_customer_sk
WHERE sd.total_spent IS NOT NULL
ORDER BY ic.warehouse_id, s.total_sales DESC;
