
WITH RECURSIVE CTE_Promotion AS (
    SELECT p.p_promo_id, p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk, p.p_discount_active, 
           ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY p.p_start_date_sk) AS promo_rank
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
CTE_CustomerInfo AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
           cd.cd_marital_status, cd.cd_income_band_sk,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
CTE_Sales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity, SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
CTE_Inventory AS (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
Final_Report AS (
    SELECT 
        cu.c_first_name, cu.c_last_name, cu.cd_gender, 
        p.p_promo_name, p.promo_rank, 
        s.total_quantity, s.total_profit, 
        i.total_stock
    FROM CTE_CustomerInfo cu
    LEFT JOIN CTE_Promotion p ON cu.cd_income_band_sk = p.p_promo_id
    LEFT JOIN CTE_Sales s ON s.ws_item_sk = p.p_promo_id
    LEFT JOIN CTE_Inventory i ON i.inv_item_sk = p.p_promo_id
    WHERE cu.gender_rank = 1 
          AND (s.total_profit IS NOT NULL OR i.total_stock IS NOT NULL)
)
SELECT * 
FROM Final_Report
ORDER BY cu.c_last_name, cu.c_first_name;
