
WITH RECURSIVE income_analysis AS (
    SELECT 
        h.hd_demo_sk,
        h.hd_income_band_sk,
        COUNT(*) AS household_count,
        SUM(CASE WHEN h.hd_buy_potential = 'High' THEN 1 ELSE 0 END) AS high_buy_potential
    FROM household_demographics h
    GROUP BY h.hd_demo_sk, h.hd_income_band_sk
),
item_analysis AS (
    SELECT 
        i.i_item_id,
        SUM(CASE WHEN ss.ss_quantity IS NULL THEN 0 ELSE ss.ss_quantity END) AS total_sales,
        AVG(COALESCE(i.i_current_price, 0)) AS avg_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ss.ss_sales_price) DESC) AS rank
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
),
customer_performance AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names,
        CASE 
            WHEN SUM(ss.ss_net_profit) > 10000 THEN 'Platinum' 
            WHEN SUM(ss.ss_net_profit) BETWEEN 5000 AND 10000 THEN 'Gold' 
            ELSE 'Silver' 
        END AS customer_tier
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
)
SELECT 
    ia.hd_income_band_sk,
    ia.household_count,
    ia.high_buy_potential,
    ia.high_buy_potential * 1.0 / ia.household_count AS buy_potential_ratio,
    ia.hd_demo_sk,
    ia.hd_income_band_sk,
    ia.household_count,
    ca.total_net_profit,
    ca.customer_names,
    (CASE 
         WHEN ia.high_buy_potential > 10 THEN 'High Engagement' 
         ELSE 'Low Engagement' 
     END) AS engagement_level,
    item.rank,
    item.total_sales,
    item.avg_price,
    item.order_count
FROM income_analysis ia
JOIN customer_performance ca ON ia.hd_demo_sk = ca.c_customer_id
JOIN item_analysis item ON ia.hd_income_band_sk = item.i_item_id
WHERE (item.total_sales IS NOT NULL AND item.total_sales > 0)
AND (ia.high_buy_potential IS NOT NULL OR ia.high_buy_potential IS NULL)
ORDER BY ia.hd_income_band_sk, item.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
