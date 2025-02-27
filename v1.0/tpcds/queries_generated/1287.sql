
WITH customer_stats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
income_summary AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(*) AS customer_count,
        SUM(cs.total_spent) AS total_spent_by_income
    FROM 
        household_demographics hd
    JOIN 
        customer_stats cs ON hd.hd_demo_sk = cs.c_customer_sk
    GROUP BY 
        hd.hd_income_band_sk
),
return_data AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
sales_data AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_sold,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_sold, 0) AS total_sold,
    COALESCE(r.total_returned, 0) AS total_returned,
    COALESCE(s.total_profit, 0) AS total_profit,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cs.total_orders,
    cs.total_spent,
    income_summary.customer_count
FROM 
    item i
LEFT JOIN 
    sales_data s ON i.i_item_sk = s.ss_item_sk
LEFT JOIN 
    return_data r ON i.i_item_sk = r.sr_item_sk
LEFT JOIN 
    income_band ib ON ib.ib_income_band_sk = (SELECT hd.hd_income_band_sk FROM household_demographics hd WHERE hd.hd_demo_sk = (SELECT cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_demo_sk IN (SELECT c.c_current_cdemo_sk FROM customer c)))
LEFT JOIN 
    customer_stats cs ON cs.total_orders > 0
WHERE 
    (s.total_sold IS NULL OR r.total_returned / NULLIF(s.total_sold, 0) < 0.2)
ORDER BY 
    total_profit DESC
LIMIT 100;
