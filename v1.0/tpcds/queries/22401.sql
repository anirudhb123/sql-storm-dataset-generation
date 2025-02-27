
WITH RECURSIVE income_aggregate AS (
    SELECT 
        ib_income_band_sk,
        CASE 
            WHEN ib_lower_bound IS NULL THEN 0 
            ELSE ib_lower_bound 
        END AS lower_bound,
        CASE 
            WHEN ib_upper_bound IS NULL THEN 1000000 
            ELSE ib_upper_bound 
        END AS upper_bound,
        COUNT(*) OVER (PARTITION BY ib_income_band_sk) AS band_count
    FROM income_band
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS gender_profit_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_marital_status, cd.cd_gender, hd.hd_income_band_sk, hd.hd_buy_potential
),
best_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_marital_status,
        ci.cd_gender,
        ci.hd_income_band_sk,
        ci.hd_buy_potential,
        ci.total_profit,
        CASE 
            WHEN ci.total_profit = 0 THEN 'No Profit'
            WHEN ci.total_profit IS NULL THEN 'Unknown Profit'
            ELSE 'Profitable'
        END AS profitability_status
    FROM customer_info ci
    WHERE ci.gender_profit_rank = 1
)
SELECT 
    ca.ca_city,
    COUNT(bc.c_customer_sk) AS top_customer_count,
    STRING_AGG(CONCAT(bc.cd_gender, ' - ', bc.hd_buy_potential), '; ') AS customer_summary
FROM best_customers bc
JOIN customer_address ca ON bc.c_customer_sk = ca.ca_address_sk
LEFT JOIN warehouse w ON w.w_warehouse_sk = (
    SELECT w_warehouse_sk 
    FROM inventory inv 
    WHERE inv.inv_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws)
    LIMIT 1
)
GROUP BY ca.ca_city
HAVING COUNT(bc.c_customer_sk) > 0 OR COUNT(bc.c_customer_sk) IS NULL
ORDER BY top_customer_count DESC, ca.ca_city;
