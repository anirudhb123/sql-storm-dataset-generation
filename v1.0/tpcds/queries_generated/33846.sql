
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        s_item_sk,
        total_quantity,
        total_net_profit
    FROM 
        sales_data
    WHERE 
        profit_rank <= 5
),
customer_address_ranked AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS city_rank
    FROM 
        customer_address ca
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address_ranked ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > (
            SELECT AVG(cd_purchase_estimate) 
            FROM customer_demographics
        )
),
final_report AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        ts.total_quantity,
        ts.total_net_profit
    FROM 
        customer_info ci
    JOIN 
        top_sales ts ON ci.c_customer_sk = (
            SELECT 
                ws_bill_customer_sk
            FROM 
                web_sales
            WHERE 
                ws_item_sk = ts.ws_item_sk
            LIMIT 1
        )
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.ca_city,
    fr.ca_state,
    fr.total_quantity,
    fr.total_net_profit,
    CASE 
        WHEN fr.total_net_profit IS NULL THEN 'No Profit' 
        ELSE 'Profitable' 
    END AS profit_status
FROM 
    final_report fr
ORDER BY 
    fr.total_net_profit DESC, 
    fr.ca_city ASC;
