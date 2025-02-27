
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_brand, i_class, i_category
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, CONCAT(ih.i_item_desc, ' -> ', i.i_item_desc), i.i_current_price, i.i_brand, i.i_class, i.i_category
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk
),
customer_spend AS (
    SELECT customer.c_customer_sk, SUM(ws.ws_net_paid) as total_spent, COUNT(DISTINCT ws.ws_order_number) as order_count
    FROM customer
    JOIN web_sales ws ON customer.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY customer.c_customer_sk
),
shipping_modes AS (
    SELECT sm.sm_ship_mode_id, sm.sm_type, COUNT(ws.ws_order_number) as order_count
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
),
customer_demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
        CASE 
            WHEN cd.purchase_estimate IS NULL THEN 'Unknown' 
            ELSE CAST(cd.purchase_estimate AS VARCHAR)
        END as purchase_estimate,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.purchase_estimate DESC) as gender_rank
    FROM customer_demographics cd
),
returns_summary AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.purchase_estimate,
    cs.total_spent,
    cs.order_count,
    sm.sm_type,
    COALESCE(r.total_returns, 0) AS total_returns,
    ih.i_item_desc,
    ih.i_current_price,
    DENSE_RANK() OVER(ORDER BY cs.total_spent DESC) as spend_rank
FROM customer c
JOIN customer_spend cs ON c.c_customer_sk = cs.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN shipping_modes sm ON cs.order_count = sm.order_count
JOIN returns_summary r ON cs.total_spent = r.total_returns
LEFT OUTER JOIN item_hierarchy ih ON sm.order_count >=ih.i_item_sk
WHERE cd.gender_rank <= 5 
AND cs.total_spent > (SELECT AVG(total_spent) FROM customer_spend)
ORDER BY cs.total_spent DESC;
