
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        COALESCE(ws_net_paid, 0) AS net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_quantity DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 10000
),
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        ROW_NUMBER() OVER (ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS rank
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY inv.inv_item_sk
),
customer_info AS (
    SELECT 
        ca.ca_address_id,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_estimate AS purchase_estimate,
        CASE
            WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'A' THEN 'Married Male'
            WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'A' THEN 'Married Female'
            ELSE 'Other'
        END AS demographic_category
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.c_customer_id,
    ci.demographic_category,
    SUM(sd.ws_quantity) AS total_quantity_sold,
    SUM(sd.net_paid) AS total_net_paid,
    COUNT(DISTINCT sd.ws_order_number) AS unique_orders,
    CASE 
        WHEN SUM(sd.net_paid) IS NULL THEN 'No Revenue'
        WHEN SUM(sd.net_paid) >= 1000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    COALESCE(ic.total_quantity_on_hand, 0) AS total_inventory
FROM customer_info ci
LEFT JOIN sales_data sd ON ci.c_customer_id = sd.ws_order_number
LEFT JOIN inventory_check ic ON sd.ws_item_sk = ic.inv_item_sk AND ic.rank <= 10
GROUP BY ci.c_customer_id, ci.demographic_category
HAVING SUM(sd.net_paid) IS NOT NULL
   OR COUNT(sd.ws_order_number) > 5
ORDER BY total_net_paid DESC, ci.demographic_category ASC
LIMIT 50
UNION ALL
SELECT 
    'Grand Total' AS c_customer_id,
    NULL AS demographic_category,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws_order_number) AS unique_orders,
    CASE 
        WHEN SUM(ws_net_paid) IS NULL THEN 'No Revenue'
        WHEN SUM(ws_net_paid) >= 1000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    NULL AS total_inventory
FROM web_sales
WHERE ws_sold_date_sk > 10000;
