
WITH RECURSIVE sale_dates AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year >= 2020
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year
    FROM date_dim d
    JOIN sale_dates sd ON d.d_date_sk = sd.d_date_sk + 1
),

customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
    AND cd.cd_gender IS NOT NULL
),

sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),

inventory_data AS (
    SELECT 
        inv_item_sk,
        AVG(inv_quantity_on_hand) AS avg_inventory
    FROM inventory
    GROUP BY inv_item_sk
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    sd.total_sales,
    sd.total_orders,
    id.avg_inventory,
    CASE 
        WHEN ci.cd_credit_rating = 'Excellent' THEN 'High Value'
        WHEN ci.cd_purchase_estimate > 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    CASE 
        WHEN sd.total_sales < COALESCE(id.avg_inventory, 0) THEN 'Stock Issue'
        ELSE 'Stock Adequate'
    END AS inventory_status
FROM customer_info ci
LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
LEFT JOIN inventory_data id ON sd.ws_item_sk = id.inv_item_sk
WHERE ci.rank <= 5
AND (ci.cd_marital_status IS NOT NULL OR ci.cd_credit_rating IS NULL)
AND EXISTS (
    SELECT 1 
    FROM store s 
    WHERE s.s_store_sk = (SELECT sr_store_sk FROM store_returns sr WHERE sr_item_sk = sd.ws_item_sk LIMIT 1)
    AND s.s_state = 'CA'
)
ORDER BY customer_value DESC, total_sales DESC;
