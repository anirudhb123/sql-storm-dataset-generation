
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        COALESCE(hd.hd_buy_potential, 'Undefined') AS buy_potential,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Estimate Missing'
            WHEN cd.cd_purchase_estimate > 500 THEN 'High Spending'
            ELSE 'Low Spending'
        END AS spending_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        (hd.hd_income_band_sk IS NULL OR hd.hd_dep_count > 3)
        AND (c.c_birth_year IS NULL OR c.c_birth_year BETWEEN 1980 AND 1990)
), 
ship_info AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
), 
total_sales AS (
    SELECT 
        a.ws_item_sk,
        COUNT(*) AS total_sales_count
    FROM 
        web_sales a
    GROUP BY 
        a.ws_item_sk
    HAVING 
        COUNT(*) > 10
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.spending_category,
    si.sm_ship_mode_id,
    si.total_orders,
    si.total_profit,
    ts.total_sales_count
FROM 
    customer_info ci
LEFT JOIN 
    ship_info si ON ci.c_customer_sk = si.total_orders
LEFT JOIN 
    total_sales ts ON ci.c_current_addr_sk = ts.ws_item_sk
WHERE 
    (ci.cd_marital_status = 'M' OR ci.cd_marital_status IS NULL)
    AND si.total_profit > (SELECT AVG(total_profit) FROM ship_info)
ORDER BY 
    ts.total_sales_count DESC, 
    ci.c_last_name ASC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
