
WITH monthly_sales AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS month,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
average_sales AS (
    SELECT 
        sales_year,
        AVG(total_net_profit) OVER (PARTITION BY sales_year) AS avg_net_profit
    FROM 
        monthly_sales
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(asales.avg_net_profit, 0) AS average_monthly_profit,
    CASE 
        WHEN asales.avg_net_profit > 0 THEN 'Above Average'
        WHEN asales.avg_net_profit < 0 THEN 'Below Average'
        ELSE 'No Profit'
    END AS profit_status
FROM 
    customer_info ci
LEFT JOIN 
    average_sales asales ON ci.c_customer_sk = asales.sales_year
LEFT JOIN 
    income_band ib ON ci.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ci.rnk = 1
AND 
    (ci.cd_gender = 'F' OR ci.cd_income_band_sk IS NOT NULL)
ORDER BY 
    average_monthly_profit DESC, 
    ci.c_last_name, 
    ci.c_first_name;
