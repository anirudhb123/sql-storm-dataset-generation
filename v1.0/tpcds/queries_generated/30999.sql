
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND ws.ws_sold_date_sk IN (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = 2023
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating

    UNION ALL

    SELECT 
        sr.returning_customer_sk,
        (SELECT c.c_first_name FROM customer c WHERE c.c_customer_sk = sr.returning_customer_sk) AS first_name,
        (SELECT c.c_last_name FROM customer c WHERE c.c_customer_sk = sr.returning_customer_sk) AS last_name,
        NULL AS cd_gender, 
        NULL AS cd_marital_status, 
        NULL AS cd_credit_rating,
        NULL AS total_orders,
        SUM(sr.sr_net_loss) AS total_profit
    FROM 
        store_returns sr
    WHERE 
        sr.returning_customer_sk IS NOT NULL
    GROUP BY 
        sr.returning_customer_sk
)

SELECT 
    ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) AS rank,
    sh.c_first_name,
    sh.c_last_name,
    sh.total_orders,
    sh.total_profit,
    COALESCE(ib.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(ib.ib_upper_bound, 1000000) AS income_upper_bound
FROM 
    SalesHierarchy sh
LEFT JOIN 
    household_demographics hd ON sh.c_customer_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    sh.total_profit IS NOT NULL
ORDER BY 
    rank;
