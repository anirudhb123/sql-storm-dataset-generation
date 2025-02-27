
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws.ship_mode_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ship_mode_sk ORDER BY SUM(ws.net_profit) DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2021) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
    GROUP BY 
        ws.ship_mode_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'Not Specified'
            ELSE CAST(cd.cd_dep_count AS VARCHAR)
        END AS dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ca.ca_city,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(IIF(ws.ws_net_paid > 100, 1, 0)) AS high_value_sales_ratio,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
    MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
    SUM(COALESCE(ws.ws_ext_discount_amt, 0)) AS total_discounts,
    (SELECT COUNT(*) FROM sales_cte WHERE total_profit > 1000) AS high_profit_count
FROM 
    web_sales ws
JOIN 
    customer_data cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    (cd.gender_rank < 5 OR cd.gender_rank IS NULL)
    AND cd.cd_marital_status = 'M'
    AND (ca.ca_state = 'NY' OR ca.ca_state IS NULL)
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ws.ws_ext_sales_price) > 10000
ORDER BY 
    total_sales DESC;
