
WITH RECURSIVE Sales_CTE AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, 
           SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
    UNION ALL
    SELECT cs_item_sk, SUM(cs_quantity) AS total_quantity, 
           SUM(cs_net_paid) AS total_sales
    FROM catalog_sales
    GROUP BY cs_item_sk
),
Inventory_Summary AS (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
Customer_Demographics AS (
    SELECT customer.c_customer_sk, cd_demo_sk, 
           (CASE 
                WHEN cd_marital_status = 'M' THEN 'Married' 
                WHEN cd_marital_status = 'S' THEN 'Single'
                ELSE 'Other' END) AS marital_status,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM customer
    JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    LEFT JOIN web_sales ON customer.c_customer_sk = ws_bill_customer_sk
    GROUP BY customer.c_customer_sk, cd_demo_sk, marital_status
)
SELECT cd.marital_status,
       COALESCE(SUM(s.total_sales), 0) AS total_web_sales,
       COALESCE(SUM(ic.total_stock), 0) AS total_inventory,
       COUNT(DISTINCT cd.c_customer_sk) AS total_customers
FROM Customer_Demographics cd
LEFT JOIN Sales_CTE s ON cd.c_customer_sk = s.ws_item_sk
LEFT JOIN Inventory_Summary ic ON ic.inv_item_sk = s.ws_item_sk
WHERE cd.total_orders > 0 
  AND cd.marital_status IS NOT NULL
GROUP BY cd.marital_status
ORDER BY total_web_sales DESC;
