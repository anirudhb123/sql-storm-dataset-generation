
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS quantity_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
        AND ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_carrier IS NOT NULL)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
profit_analysis AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.gender,
        ci.marital_status,
        ci.total_profit,
        CASE 
            WHEN ci.total_profit = 0 THEN 'No Profit'
            WHEN ci.total_profit < 100 THEN 'Low Profit'
            WHEN ci.total_profit BETWEEN 100 AND 500 THEN 'Moderate Profit'
            ELSE 'High Profit'
        END AS profit_category
    FROM 
        customer_info ci
    WHERE 
        ci.total_profit > (SELECT AVG(total_profit) FROM customer_info)
)
SELECT 
    pa.c_customer_sk,
    pa.c_first_name,
    pa.c_last_name,
    pa.gender,
    pa.marital_status,
    pa.total_profit,
    pa.profit_category,
    COALESCE(SUM(rs.ws_net_profit), 0) AS additional_profit,
    CASE 
        WHEN pa.profit_category = 'No Profit' THEN 'Customer is not engaged'
        ELSE 'Customer is engaged'
    END AS engagement_status
FROM 
    profit_analysis pa
LEFT JOIN 
    ranked_sales rs ON pa.c_customer_sk = rs.ws_item_sk
GROUP BY 
    pa.c_customer_sk, pa.c_first_name, pa.c_last_name, pa.gender, 
    pa.marital_status, pa.total_profit, pa.profit_category
HAVING 
    COUNT(DISTINCT rs.ws_order_number) > 2
ORDER BY 
    pa.total_profit DESC, engagement_status ASC
OFFSET 10 ROWS FETCH NEXT 30 ROWS ONLY;
