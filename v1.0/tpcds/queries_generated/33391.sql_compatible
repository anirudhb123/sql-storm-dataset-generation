
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_spent
    FROM 
        customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
income_summary AS (
    SELECT 
        cd.cd_income_band_sk,
        COUNT(DISTINCT c.customer_sk) AS customer_count,
        SUM(ci.total_spent) AS total_spent
    FROM 
        customer_info ci
    JOIN customer_demographics cd ON ci.cd_income_band_sk = cd.cd_income_band_sk
    GROUP BY 
        cd.cd_income_band_sk
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(is.customer_count, 0) AS customer_count,
    COALESCE(is.total_spent, 0) AS total_spent,
    (SELECT AVG(ws_list_price) 
     FROM web_sales ws 
     JOIN item i ON ws.ws_item_sk = i.i_item_sk 
     WHERE i.i_item_id IN (SELECT ws_item_sk FROM sales_data WHERE rank <= 10)) AS avg_top_item_price
FROM 
    income_band ib
LEFT JOIN income_summary is ON ib.ib_income_band_sk = is.cd_income_band_sk
WHERE 
    ib.ib_lower_bound >= 0 AND ib.ib_upper_bound <= 50000
ORDER BY 
    ib.ib_lower_bound;
