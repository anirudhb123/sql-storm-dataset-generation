
WITH RECURSIVE sales_performance AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
customer_preferences AS (
    SELECT 
        c.c_customer_sk,
        MAX(cd.cd_gender) AS preferred_gender,
        MAX(cd.cd_marital_status) AS marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
top_profit_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sp.total_profit,
        DENSE_RANK() OVER (ORDER BY sp.total_profit DESC) AS profit_rank
    FROM 
        sales_performance sp
    JOIN 
        item ON sp.cs_item_sk = item.i_item_sk
    WHERE 
        sp.total_profit IS NOT NULL
),
high_value_customers AS (
    SELECT 
        cp.c_customer_sk, 
        SUM(s.ws_net_profit) AS customer_profit,
        ROW_NUMBER() OVER (PARTITION BY cp.preferred_gender ORDER BY SUM(s.ws_net_profit) DESC) AS rank_by_gender
    FROM 
        customer_preferences cp
    JOIN 
        web_sales s ON cp.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        s.ws_net_profit IS NOT NULL
    GROUP BY 
        cp.c_customer_sk, cp.preferred_gender
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_profit,
    hc.c_customer_sk,
    hc.customer_profit
FROM 
    top_profit_items ti
CROSS JOIN 
    (SELECT c.c_customer_sk FROM high_value_customers hc WHERE hc.rank_by_gender <= 10) AS hc
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT sm_ship_mode_sk FROM catalog_sales WHERE cs_item_sk = ti.i_item_id LIMIT 1)
WHERE 
    ti.total_profit IS NOT NULL 
    AND (hc.customer_profit / NULLIF(ti.total_profit, 0)) > 0.05
ORDER BY 
    ti.total_profit DESC, hc.customer_profit DESC;
