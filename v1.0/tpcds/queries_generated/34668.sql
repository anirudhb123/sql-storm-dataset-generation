
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_profit) > 0
),
address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        COALESCE(a.full_address, 'Unknown') AS address,
        SUM( CASE 
            WHEN ss_quantity > 10 THEN ss_net_profit 
            ELSE 0 
        END ) AS high_value_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        address_info a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.cd_gender, d.cd_marital_status, d.cd_purchase_estimate, a.full_address
),
sales_summary AS (
    SELECT 
        sd.c_customer_sk,
        sd.c_first_name,
        sd.c_last_name,
        sd.address,
        sd.cd_gender,
        sd.cd_marital_status,
        sd.cd_purchase_estimate,
        SUM(cs.net_profit) AS catalog_net_profit,
        SUM(ws.net_profit) AS web_net_profit,
        sd.high_value_net_profit
    FROM 
        customer_data sd
    LEFT JOIN 
        catalog_sales cs ON cs.cs_bill_customer_sk = sd.c_customer_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = sd.c_customer_sk
    GROUP BY 
        sd.c_customer_sk, sd.c_first_name, sd.c_last_name, sd.address, sd.cd_gender, sd.cd_marital_status, sd.cd_purchase_estimate, sd.high_value_net_profit
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.address,
    s.cd_gender,
    s.cd_marital_status,
    s.cd_purchase_estimate,
    s.catalog_net_profit,
    s.web_net_profit,
    s.high_value_net_profit,
    COALESCE(s.catalog_net_profit, 0) + COALESCE(s.web_net_profit, 0) AS total_profit,
    ROW_NUMBER() OVER (ORDER BY s.total_profit DESC) AS ranking
FROM 
    sales_summary s
WHERE 
    s.high_value_net_profit > (SELECT AVG(high_value_net_profit) FROM customer_data)
ORDER BY 
    ranking
FETCH FIRST 50 ROWS ONLY;
