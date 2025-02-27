
WITH RECURSIVE sales_cte AS (
    SELECT 
        s_store_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ws_net_profit) DESC) AS store_rank
    FROM 
        web_sales
    GROUP BY 
        s_store_sk
    HAVING 
        SUM(ws_net_profit) > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        si.s_store_sk, 
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        store si ON ws.ws_warehouse_sk = si.s_store_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        si.s_store_sk
)

SELECT 
    si.s_store_sk,
    si.s_store_name,
    ss.total_orders,
    ss.unique_customers,
    ss.total_net_profit,
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.hd_buy_potential,
    CASE
        WHEN ci.hd_income_band_sk IS NULL THEN 'Not specified'
        ELSE ci.hd_income_band_sk
    END AS income_band,
    sales_cte.total_profit
FROM 
    sales_summary ss
JOIN 
    store si ON ss.s_store_sk = si.s_store_sk
LEFT JOIN 
    customer_info ci ON ci.c_customer_sk = (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_warehouse_sk = si.s_store_sk LIMIT 1)
LEFT JOIN
    sales_cte ON sales_cte.s_store_sk = si.s_store_sk
WHERE 
    sales_cte.store_rank <= 5
ORDER BY 
    total_net_profit DESC, total_orders ASC;
