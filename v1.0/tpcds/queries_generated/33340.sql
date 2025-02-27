
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        (CASE 
            WHEN cd.cd_purchase_estimate >= 1000 THEN 'High Value'
            ELSE 'Regular'
        END) AS customer_segment
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
),
top_incomes AS (
    SELECT 
        hd.hd_demo_sk,
        MAX(ib.ib_upper_bound) AS max_income
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        hd.hd_buy_potential = 'High'
    GROUP BY 
        hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_net_profit,
        hic.max_income,
        hc.customer_segment
    FROM 
        customer_sales cs
    LEFT JOIN 
        high_value_customers hc ON cs.c_customer_id = hc.c_customer_sk
    LEFT JOIN 
        top_incomes hic ON hc.c_customer_id = hic.hd_demo_sk
    WHERE 
        cs.sales_rank = 1
)
SELECT 
    s_summary.c_customer_id,
    s_summary.total_net_profit,
    s_summary.max_income,
    s_summary.customer_segment,
    (CASE 
        WHEN s_summary.total_net_profit IS NULL THEN 'No Profit'
        ELSE CONCAT('Profit: $', FORMAT(s_summary.total_net_profit, 2))
    END) AS profit_info
FROM 
    sales_summary s_summary
WHERE 
    s_summary.total_net_profit IS NOT NULL
ORDER BY 
    s_summary.total_net_profit DESC
LIMIT 10;
