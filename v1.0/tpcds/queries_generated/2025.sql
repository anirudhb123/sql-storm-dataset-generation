
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(NULLIF(cd.cd_credit_rating, 'Unknown'), 'Not Specified') AS credit_rating,
        COUNT(DISTINCT sw.ws_order_number) AS web_orders,
        SUM(sw.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales sw ON c.c_customer_sk = sw.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
IncomeBandStats AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(CASE WHEN cs.total_spent IS NOT NULL THEN cs.total_spent ELSE 0 END) AS total_income
    FROM 
        income_band ib
    LEFT JOIN 
        (SELECT 
            cd_demo_sk, 
            total_spent, 
            CASE 
                WHEN total_spent < 1000 THEN 1 
                WHEN total_spent BETWEEN 1000 AND 5000 THEN 2 
                WHEN total_spent BETWEEN 5001 AND 10000 THEN 3 
                ELSE 4 
            END AS income_band
        FROM 
            CustomerStats cs) AS c_stat ON c_stat.income_band = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
),
FinalStats AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ibs.total_income,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY ibs.total_income DESC) AS income_rank
    FROM 
        CustomerStats cs
    LEFT JOIN 
        IncomeBandStats ibs ON cs.cd_purchase_estimate BETWEEN ibs.ib_lower_bound AND ibs.ib_upper_bound
    JOIN 
        income_band ib ON ib.ib_income_band_sk = ibs.ib_income_band_sk
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.ib_lower_bound,
    f.ib_upper_bound,
    f.total_income,
    f.income_rank,
    CASE 
        WHEN f.income_rank <= 10 THEN 'Top 10%'
        WHEN f.income_rank > 10 AND f.income_rank <= 30 THEN 'Top 30%'
        ELSE 'Others' 
    END AS income_group
FROM 
    FinalStats f
WHERE 
    f.total_income IS NOT NULL 
ORDER BY 
    f.cd_gender, f.income_rank;
