
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country, ah.level + 1
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ca_state IS NOT NULL AND ah.level < 5
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year >= 2020 AND d.d_year <= 2023
    GROUP BY c.c_customer_id, d.d_year, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_profit,
        cs.total_orders,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM CustomerSummary cs
    WHERE cs.total_orders > 5
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid 
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE w.w_country = 'USA'
    GROUP BY w.w_warehouse_id
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    ah.ca_country,
    tc.c_customer_id,
    tc.total_profit,
    tc.total_orders,
    ws.total_sales,
    ws.avg_net_paid,
    CASE
        WHEN tc.total_profit > 1000 THEN 'High Roller'
        ELSE 'Regular'
    END AS customer_type
FROM AddressHierarchy ah
FULL OUTER JOIN TopCustomers tc ON tc.total_profit IS NOT NULL
LEFT JOIN WarehouseSales ws ON ws.total_sales IS NOT NULL
WHERE 
    ah.level = 1 
    AND (tc.total_orders > 10 OR ws.avg_net_paid IS NOT NULL)
    AND (
        EXISTS (
            SELECT 1 
            FROM item i 
            WHERE i.i_item_id LIKE '%Gadget%' 
            AND i.i_current_price > 50
            HAVING COUNT(DISTINCT i.i_item_sk) > 2
        )
    OR 
        tc.total_profit IS NULL
    )
ORDER BY ah.ca_country, tc.total_profit DESC;
