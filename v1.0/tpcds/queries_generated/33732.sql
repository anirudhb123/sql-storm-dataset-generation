
WITH RECURSIVE Sales_CTE AS (
    SELECT s_store_sk, SUM(ss_net_paid) AS total_sales
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT max(d_date_sk) FROM date_dim)
    GROUP BY s_store_sk
    UNION ALL
    SELECT s_store_sk, SUM(ss_net_paid) AS total_sales
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT max(d_date_sk) - 1 FROM date_dim)
    GROUP BY s_store_sk
),
Customer_Info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_income_band_sk, 
           COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
Shipping_Summary AS (
    SELECT ws_ship_mode_sk, COUNT(*) AS total_shipments
    FROM web_sales
    GROUP BY ws_ship_mode_sk
),
Income_Band_Analysis AS (
    SELECT ib.ib_income_band_sk, 
           SUM(CASE 
                   WHEN cd.cd_credit_rating IS NULL THEN 1 
                   ELSE 0 
               END) AS no_credit_rating_count,
           COUNT(*) AS total_customers
    FROM Customer_Info ci
    JOIN income_band ib ON ci.cd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    s.w_warehouse_id, 
    s.total_sales,
    ci.c_first_name, 
    ci.c_last_name, 
    ci.buy_potential,
    COALESCE(sha.total_shipments, 0) AS total_shipments,
    ia.no_credit_rating_count,
    ia.total_customers
FROM Sales_CTE s
JOIN Customer_Info ci ON ci.c_customer_sk IN (SELECT sr_customer_sk FROM store_returns)
LEFT JOIN Shipping_Summary sha ON s.s_store_sk = sha.ws_ship_mode_sk
LEFT JOIN Income_Band_Analysis ia ON ci.cd_income_band_sk = ia.ib_income_band_sk
WHERE ci.cd_gender = 'M' 
AND ia.total_customers > 0
ORDER BY total_sales DESC;
