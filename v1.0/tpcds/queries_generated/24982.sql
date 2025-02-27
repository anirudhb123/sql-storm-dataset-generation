
WITH RECURSIVE income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT 
        ib_income_band_sk,
        (ib_lower_bound - 1000) AS ib_lower_bound,
        (ib_upper_bound - 1000) AS ib_upper_bound
    FROM income_ranges
    WHERE ib_lower_bound > 0
), 
warehouse_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN' 
            ELSE CASE 
                WHEN cd.cd_purchase_estimate < 50 THEN 'LOW'
                WHEN cd.cd_purchase_estimate BETWEEN 50 AND 150 THEN 'MEDIUM'
                ELSE 'HIGH'
            END 
        END AS purchase_estimate_category,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
filtered_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_marital_status,
        ci.purchase_estimate_category,
        wi.total_quantity_on_hand
    FROM customer_info ci
    LEFT JOIN warehouse_inventory wi ON wi.inv_item_sk IN (
        SELECT i_item_sk 
        FROM item 
        WHERE i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_rec_start_date IS NOT NULL)
    )
    WHERE ci.rn <= 10
)
SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    fc.cd_marital_status,
    fc.purchase_estimate_category,
    COALESCE(fc.total_quantity_on_hand, 0) AS available_inventory,
    CASE
        WHEN fc.cd_marital_status = 'M' AND fc.purchase_estimate_category = 'HIGH' THEN 'Target for Premium Offers'
        WHEN fc.cd_marital_status = 'S' AND fc.purchase_estimate_category = 'LOW' THEN 'Consider Retargeting'
        ELSE 'General Inquiry'
    END AS marketing_opportunity,
    STRING_AGG(w.w_warehouse_name, ', ') FILTER (WHERE w.w_warehouse_sq_ft > 5000) AS large_warehouses
FROM filtered_customers fc
LEFT JOIN warehouse w ON fc.total_quantity_on_hand > 0
GROUP BY fc.c_customer_sk, fc.c_first_name, fc.c_last_name, fc.cd_marital_status, fc.purchase_estimate_category
ORDER BY fc.c_last_name, fc.c_first_name;
