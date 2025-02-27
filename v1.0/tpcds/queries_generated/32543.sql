
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        total_quantity + 1 AS total_quantity,
        total_sales + 10.00 AS total_sales
    FROM Sales_CTE
    WHERE total_quantity < 100
),
Order_Summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid_inc_tax) AS average_sale
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
Filtered_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(od.order_count, 0) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN Order_Summary od ON c.c_customer_sk = od.ws_bill_customer_sk
    WHERE cd.cd_credit_rating IN ('Excellent', 'Good') 
      AND cd.cd_purchase_estimate > 1000
),
Inventory_Summary AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    fc.order_count,
    is.total_inventory,
    ss.total_quantity,
    ss.total_sales
FROM Filtered_Customers fc
JOIN Inventory_Summary is ON fc.c_customer_sk = is.inv_item_sk
LEFT JOIN Sales_CTE ss ON fc.order_count > 0 
WHERE is.total_inventory > 50
ORDER BY ss.total_sales DESC, fc.c_last_name ASC
LIMIT 100;
