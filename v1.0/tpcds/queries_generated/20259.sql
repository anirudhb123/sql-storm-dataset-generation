
WITH RECURSIVE Sales_CTE AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_sales
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2458852 AND 2458919
    GROUP BY
        ws.ws_item_sk
),
Customer_Summary AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        SUM(cs.cs_net_paid) AS total_catalog_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_spent
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
Inventory_Status AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        CASE
            WHEN inv.inv_quantity_on_hand < 10 THEN 'Low Stock'
            WHEN inv.inv_quantity_on_hand BETWEEN 10 AND 50 THEN 'Medium Stock'
            ELSE 'High Stock'
        END AS stock_status
    FROM
        inventory inv
    WHERE
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
)
SELECT
    cs.c_customer_sk,
    cs.gender,
    cs.total_catalog_orders,
    cs.total_catalog_spent,
    cs.total_web_orders,
    cs.total_web_spent,
    is.stock_status,
    sc.total_quantity,
    sc.total_sales
FROM
    Customer_Summary cs
LEFT JOIN
    Inventory_Status is ON cs.total_catalog_orders > 5 AND cs.total_web_orders > 5 
    AND exists (SELECT 1 FROM Sales_CTE sc WHERE sc.ws_item_sk IN (SELECT i.inv_item_sk FROM inventory i WHERE i.inv_quantity_on_hand < 20))
JOIN
    Sales_CTE sc ON sc.rank_sales <= 10
WHERE
    (cs.gender IS NOT NULL OR cs.total_catalog_spent > 100)
    AND (cs.total_web_spent IS NULL OR cs.total_web_spent > 50)
ORDER BY
    cs.c_customer_sk,
    sc.total_sales DESC;
