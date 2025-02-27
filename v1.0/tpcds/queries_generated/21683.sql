
WITH CustomerOrders AS (
    SELECT c.c_customer_id, SUM(ws_ext_sales_price) AS Total_Sales,
           COUNT(DISTINCT ws_order_number) AS Order_Count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
    GROUP BY c.c_customer_id
),
HighValueCustomers AS (
    SELECT c.c_customer_id, cd.cd_gender, cd.cd_marital_status,
           cd.cd_purchase_estimate, cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 100000
),
PromotionsApplied AS (
    SELECT ws.ws_order_number, p.p_promo_name, ws.ws_net_paid,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS Promo_Rank
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_net_paid > 0
)
SELECT 
    co.c_customer_id, co.Total_Sales, co.Order_Count,
    hvc.cd_gender, hvc.cd_marital_status, hvc.cd_purchase_estimate, hvc.cd_credit_rating,
    pa.p_promo_name, pa.ws_net_paid AS Promotional_Sales,
    CASE WHEN pa.ws_net_paid IS NULL THEN 'No Promotion' ELSE 'Promotion Applied' END AS Promotion_Status,
    (CASE 
        WHEN cd_cd_purchase_estimate IS NULL THEN 'No Value'
        WHEN cd_cd_purchase_estimate > 150000 THEN 'High'
        ELSE 'Medium'
     END) AS Purchase_Band
FROM CustomerOrders co
FULL OUTER JOIN HighValueCustomers hvc ON co.c_customer_id = hvc.c_customer_id
LEFT JOIN PromotionsApplied pa ON pa.ws_order_number IN (SELECT ws_order_number FROM PromotionsApplied pa2)
WHERE co.Total_Sales IS NOT NULL OR hvc.cd_gender IS NOT NULL
ORDER BY co.Total_Sales DESC NULLS LAST, hvc.cd_gender ASC;

SELECT DISTINCT w.w_warehouse_name, SUM(ws.ws_net_profit) AS Total_Profit
FROM warehouse w
JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
WHERE EXISTS (SELECT 1 FROM store s WHERE s.s_store_sk = ws.ws_ship_addr_sk)
GROUP BY w.w_warehouse_name
HAVING SUM(ws.ws_net_profit) > 1000
UNION ALL
SELECT 'Total Profit Across all Warehouses' AS Warehouse_Name, SUM(ws.ws_net_profit) AS Total_Profit
FROM web_sales ws
WHERE ws.ws_net_profit IS NOT NULL;
