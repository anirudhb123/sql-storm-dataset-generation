
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        DENSE_RANK() OVER (ORDER BY cd.cd_credit_rating) AS credit_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
        AND cd.cd_gender IS NOT NULL
),
total_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
sales_summary AS (
    SELECT
        ti.ws_item_sk,
        COALESCE(ts.total_quantity, 0) AS total_qty,
        COALESCE(ts.total_profit, 0) AS total_profit,
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        RANK() OVER (PARTITION BY ti.ws_item_sk ORDER BY COALESCE(ts.total_profit, 0) DESC) AS profit_rank
    FROM 
        ranked_sales ti
    LEFT JOIN 
        total_sales ts ON ti.ws_item_sk = ts.ws_item_sk
    LEFT JOIN 
        customer_info ci ON ci.credit_rank = 1
)
SELECT 
    ss.ws_item_sk,
    ss.total_qty,
    ss.total_profit,
    IF(ss.total_profit > 0, 'Profitable', 'Unprofitable') AS profitability_status
FROM 
    sales_summary ss
WHERE 
    ss.profit_rank <= 5
    AND ss.total_qty IS NOT NULL
ORDER BY 
    ss.total_profit DESC;
