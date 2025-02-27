
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank_within_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
promotions_info AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer_info ci
    JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender
    HAVING SUM(ws.ws_net_paid) > 1000
),
warehouse_item_sales AS (
    SELECT 
        inv.inv_warehouse_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM inventory inv
    JOIN web_sales ws ON inv.inv_item_sk = ws.ws_item_sk
    WHERE inv.inv_quantity_on_hand > 0
    GROUP BY inv.inv_warehouse_sk, ws.ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    TRIM(CONCAT(ci.c_first_name, ' ', ci.c_last_name)) AS full_name,
    pi.p_promo_name,
    pi.total_net_paid AS promo_total_sales,
    COALESCE(wis.total_quantity_sold, 0) AS total_item_sales,
    CASE 
        WHEN ci.rank_within_gender <= 10 THEN 'Top 10' 
        ELSE 'Others' 
    END AS customer_ranking
FROM top_customers ci
LEFT JOIN promotions_info pi ON pi.total_net_paid > 5000
LEFT JOIN warehouse_item_sales wis ON wis.inv_warehouse_sk = (SELECT MIN(wh.w_warehouse_sk) FROM warehouse wh)
WHERE ci.cd_gender = 'F'
ORDER BY ci.c_last_name ASC, ci.c_first_name ASC;
