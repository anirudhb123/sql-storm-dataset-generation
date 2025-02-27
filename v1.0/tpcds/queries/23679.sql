
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_purchase_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
most_profitable_customers AS (
    SELECT 
        cps.c_customer_sk,
        cps.total_spent,
        cps.total_orders,
        (SELECT AVG(total_spent) FROM customer_purchase_summary) AS average_spent
    FROM customer_purchase_summary cps
    WHERE cps.total_spent > (SELECT AVG(total_spent) FROM customer_purchase_summary) 
),
address_details AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS address_rank
    FROM customer_address ca
),
inventory_status AS (
    SELECT 
        i.i_item_sk,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_quantity
    FROM item i
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    c.c_customer_sk,
    c.c_email_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cps.total_spent,
    cps.total_orders,
    ad.ca_city,
    ad.ca_state,
    inv.total_quantity,
    CASE 
        WHEN inv.total_quantity IS NULL THEN 'No Inventory'
        WHEN inv.total_quantity < 10 THEN 'Low Inventory'
        ELSE 'Sufficient Inventory'
    END AS inventory_status
FROM ranked_customers rc
JOIN customer c ON rc.c_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_purchase_summary cps ON c.c_customer_sk = cps.c_customer_sk
LEFT JOIN address_details ad ON ad.ca_address_sk = c.c_current_addr_sk
LEFT JOIN inventory_status inv ON inv.i_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
WHERE rc.rn = 1
AND (cps.total_orders > 5 OR cd.cd_marital_status IS NULL)
ORDER BY c.c_customer_sk, inv.total_quantity DESC;
