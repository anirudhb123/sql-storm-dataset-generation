
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
top_sales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        ranked_sales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_order_number
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_id,
        COUNT(ts.ws_order_number) AS order_count,
        SUM(ts.total_quantity) AS total_sales_quantity,
        SUM(ts.total_net_profit) AS total_sales_profit
    FROM 
        customer_info ci
    LEFT JOIN 
        top_sales ts ON ci.c_customer_id = ts.ws_order_number
    GROUP BY 
        ci.c_customer_id
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.order_count,
    ss.total_sales_quantity,
    ss.total_sales_profit,
    CASE 
        WHEN ss.total_sales_profit IS NULL THEN 'No Sales'
        WHEN ss.total_sales_profit > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value_category
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_id = ss.c_customer_id
WHERE 
    ci.cd_gender = 'F' 
    AND (ci.ib_lower_bound > 50000 OR ci.ib_upper_bound < 100000)
ORDER BY 
    ss.total_sales_profit DESC
LIMIT 100;
