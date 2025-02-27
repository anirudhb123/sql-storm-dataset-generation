
WITH CustomerAnalysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value,
        MAX(ws.ws_sold_date_sk) AS last_order_date,
        DATEDIFF(CURRENT_DATE, MAX(ws.ws_sold_date_sk)) AS days_since_last_order
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
IncomeGroups AS (
    SELECT
        hd.hd_demo_sk,
        CASE 
            WHEN ib.ib_income_band_sk IS NOT NULL THEN 
                CASE 
                    WHEN hd.hd_income_band_sk IS NOT NULL THEN ib.ib_lower_bound
                    ELSE 0
                END
            ELSE NULL
        END AS income_lower_bound,
        CASE 
            WHEN ib.ib_income_band_sk IS NOT NULL THEN 
                CASE 
                    WHEN hd.hd_income_band_sk IS NOT NULL THEN ib.ib_upper_bound
                    ELSE NULL 
                END 
            ELSE NULL
        END AS income_upper_bound
    FROM 
        household_demographics hd
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
FinalReport AS (
    SELECT 
        ca.c_customer_sk,
        ca.c_first_name,
        ca.c_last_name,
        ca.cd_gender,
        ca.total_orders,
        ca.total_spent,
        ca.avg_order_value,
        ig.income_lower_bound,
        ig.income_upper_bound,
        ca.days_since_last_order
    FROM 
        CustomerAnalysis ca
    LEFT JOIN IncomeGroups ig ON ca.c_customer_sk = ig.hd_demo_sk
    WHERE 
        (ca.days_since_last_order < 30 AND ca.total_orders > 5) 
        OR (ca.days_since_last_order >= 30 AND ca.total_spent > 1000)
)
SELECT 
    *,
    CASE 
        WHEN total_orders > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status,
    CASE 
        WHEN total_spent BETWEEN 0 AND 100 THEN 'Low Spender'
        WHEN total_spent BETWEEN 101 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    FinalReport
WHERE 
    income_lower_bound IS NOT NULL AND income_upper_bound IS NOT NULL
ORDER BY 
    total_spent DESC, total_orders DESC;
