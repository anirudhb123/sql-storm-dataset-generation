
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound < 50000
    
    UNION ALL
    
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_brackets ib_temp ON ib.ib_lower_bound >= ib_temp.ib_upper_bound
    WHERE ib.ib_lower_bound < 150000
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        hd.hd_income_band_sk
),
profit_analysis AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ib.ib_income_band_sk,
        ci.total_profit,
        ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ci.total_profit DESC) AS rank
    FROM 
        customer_info ci
    JOIN 
        income_brackets ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ci.total_profit IS NOT NULL
)
SELECT 
    pa.c_first_name,
    pa.c_last_name,
    pa.cd_gender,
    pa.total_profit,
    CASE 
        WHEN pa.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    profit_analysis pa
WHERE 
    pa.ib_income_band_sk IS NOT NULL
ORDER BY 
    pa.cd_gender, 
    pa.total_profit DESC;
