
WITH RECURSIVE weekly_sales AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
),
income_distribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(h.hd_dep_count) AS avg_dependents
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        h.hd_income_band_sk
)
SELECT 
    w.w_warehouse_name,
    COALESCE(week.sale_date, 'No Sales') AS sale_date,
    week.total_quantity,
    week.total_profit,
    income.hd_income_band_sk,
    income.customer_count,
    income.avg_dependents
FROM 
    warehouse w
LEFT JOIN 
    weekly_sales week ON week.sale_date = CURRENT_DATE - INTERVAL '7 days'
LEFT JOIN 
    income_distribution income ON income.hd_income_band_sk = 
    (SELECT 
         hd_income_band_sk 
     FROM 
         household_demographics 
     WHERE 
         hd_dep_count > 2 
         LIMIT 1)
WHERE 
    w.w_warehouse_sq_ft > 10000
ORDER BY 
    week.total_profit DESC NULLS LAST
LIMIT 10;
