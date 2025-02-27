
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cc_name,
        cc_division_name,
        cc_employees,
        cc_sq_ft,
        0 AS Level
    FROM call_center
    WHERE cc_division_name IS NOT NULL

    UNION ALL

    SELECT 
        ch.cc_name,
        ch.cc_division_name,
        ch.cc_employees,
        ch.cc_sq_ft,
        Level + 1
    FROM call_center ch
    JOIN SalesHierarchy sh ON ch.cc_manager = sh.cc_name
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS purchase_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.total_spent,
        cd.cd_gender,
        cd.cd_marital_status,
        address.ca_state,
        CASE 
            WHEN cp.total_spent IS NULL THEN 'No Purchases'
            WHEN cp.total_spent > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS value_category
    FROM CustomerPurchases cp
    LEFT JOIN customer_demographics cd ON cp.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN customer_address address ON c.c_current_addr_sk = address.ca_address_sk
)
SELECT 
    sh.cc_name,
    SUM(hv.total_spent) AS total_income,
    AVG(inv_quantity_on_hand) AS avg_inventory,
    COUNT(DISTINCT hv.c_customer_sk) AS number_of_customers
FROM SalesHierarchy sh
LEFT JOIN HighValueCustomers hv ON sh.cc_division_name = hv.cd_marital_status
LEFT JOIN inventory inv ON sh.cc_name = inv.inv_item_sk
WHERE 
    sh.cc_employees IS NOT NULL 
    AND hv.total_spent IS NOT NULL
GROUP BY 
    sh.cc_name
HAVING 
    total_income > 50000
ORDER BY 
    total_income DESC;
