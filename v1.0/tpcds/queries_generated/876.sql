
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
highest_sales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_net_profit,
        DENSE_RANK() OVER (ORDER BY total_net_profit DESC) AS sales_rank
    FROM sales_summary
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    hs.total_quantity,
    hs.total_net_profit
FROM customer_info ci
LEFT JOIN highest_sales hs ON ci.c_customer_sk = hs.ws_item_sk
WHERE 
    ci.rn <= 10
    AND (hs.total_net_profit IS NOT NULL OR ci.cd_marital_status = 'M')
ORDER BY 
    ci.cd_gender, 
    hs.total_net_profit DESC;
