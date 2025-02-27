
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_net_profit) DESC) AS rank_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
    GROUP BY 
        ss_customer_sk
),
Customer_Info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        RANK() OVER (ORDER BY SUM(ss.net_profit) DESC) AS rank_by_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_income_band_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_income_band_sk,
    COALESCE(sc.total_profit, 0) AS total_profit,
    CASE WHEN ci.rank_by_gender = 1 THEN 'Top Contributor'
         ELSE 'Regular Contributor'
    END AS contribution_status
FROM 
    Customer_Info ci
FULL OUTER JOIN 
    Sales_CTE sc ON ci.ss_customer_sk = sc.ss_customer_sk
WHERE 
    (ci.cd_income_band_sk IS NOT NULL AND ci.cd_income_band_sk > 0)
ORDER BY 
    total_profit DESC, ci.c_last_name;
