
WITH CustomerGender AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CityWarehouse AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_city,
        w.w_warehouse_name,
        COUNT(DISTINCT i.i_item_sk) AS item_count
    FROM warehouse w
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_city, w.w_warehouse_name
),
StringMetrics AS (
    SELECT 
        c.full_name,
        LENGTH(c.full_name) AS name_length,
        REPLACE(REPLACE(c.full_name, ' ', ''), '-', '') AS name_without_spaces,
        LENGTH(REPLACE(REPLACE(c.full_name, ' ', ''), '-', '')) AS name_without_space_length
    FROM CustomerGender c
),
CustomerRank AS (
    SELECT 
        sm.sm_carrier,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM store_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_carrier
)
SELECT 
    cm.full_name,
    cm.name_length,
    cm.name_without_space_length,
    cw.w_city,
    cw.w_warehouse_name,
    cr.sm_carrier,
    cr.order_count,
    cr.total_sales
FROM StringMetrics cm
JOIN CityWarehouse cw ON cm.name_length % 5 = 0
JOIN CustomerRank cr ON char_length(cm.full_name) + cr.order_count = 100
ORDER BY cm.name_length DESC, cr.total_sales DESC;
