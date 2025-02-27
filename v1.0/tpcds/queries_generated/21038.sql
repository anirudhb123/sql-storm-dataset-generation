
WITH RECURSIVE income_summary AS (
    SELECT 
        cd_income_band_sk,
        COUNT(*) AS customer_count,
        SUM(hd_vehicle_count) AS total_vehicles,
        SUM(hd_dep_count) AS total_dependents,
        COUNT(DISTINCT c_customer_id) AS unique_customers
    FROM 
        household_demographics 
    JOIN 
        customer ON hd_demo_sk = c_current_hdemo_sk
    GROUP BY 
        cd_income_band_sk
),
purchase_summary AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(cs_order_number) AS order_count
    FROM 
        catalog_sales 
    GROUP BY 
        cs_bill_customer_sk
),
negative_net_profit AS (
    SELECT 
        ws_ship_customer_sk, 
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales 
    GROUP BY 
        ws_ship_customer_sk 
    HAVING 
        SUM(ws_net_profit) < 0
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COALESCE(iss.customer_count, 0) AS customer_count,
    COALESCE(ps.total_net_profit, 0) AS total_net_profit,
    COALESCE(pn.total_net_profit, 0) AS negative_net_profit 
FROM 
    customer_address ca
LEFT JOIN 
    income_summary iss ON ca.ca_address_sk = iss.cd_income_band_sk
LEFT JOIN 
    purchase_summary ps ON ps.cs_bill_customer_sk = iss.cd_income_band_sk
LEFT JOIN 
    negative_net_profit pn ON pn.ws_ship_customer_sk = iss.cd_income_band_sk
WHERE 
    (iss.customer_count IS NOT NULL OR ps.total_net_profit IS NOT NULL)
    AND (ca.ca_state IN ('CA', 'TX') OR (ca.ca_city LIKE '%town%' AND iss.customer_count < 5))
ORDER BY 
    ca.ca_city DESC, 
    customer_count DESC 
FETCH FIRST 100 ROWS ONLY;
