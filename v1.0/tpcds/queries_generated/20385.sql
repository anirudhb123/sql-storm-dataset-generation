
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
aggregated_sales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_net_profit) AS total_net_profit,
        COUNT(sd.ws_item_sk) AS items_sold
    FROM 
        sales_data sd
    WHERE 
        sd.rn < 5 -- Get top 4 profitable items for each order
    GROUP BY 
        sd.ws_order_number
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COALESCE(SUM(as.total_net_profit), 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        aggregated_sales as ON ws.ws_order_number = as.ws_order_number
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
final_report AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.order_count,
        ci.total_profit,
        CASE 
            WHEN ci.total_profit >= 1000 THEN 'Gold'
            WHEN ci.total_profit >= 500 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM 
        customer_info ci
)
SELECT 
    fr.c_customer_id,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.order_count,
    fr.total_profit,
    fr.customer_tier,
    CASE 
        WHEN fr.cd_gender IS NULL THEN 'Gender Not Specified'
        ELSE fr.cd_gender
    END AS gender_status
FROM 
    final_report fr
WHERE 
    fr.order_count > 0
ORDER BY 
    fr.total_profit DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
