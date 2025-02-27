
WITH RECURSIVE income_analysis AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS orders_count,
        COUNT(DISTINCT c.c_customer_id) OVER () AS total_customers,
        CASE 
            WHEN SUM(ws.ws_net_paid) IS NULL OR SUM(ws.ws_net_paid) = 0 THEN 'No Spend'
            WHEN SUM(ws.ws_net_paid) < 100 THEN 'Low Spend'
            WHEN SUM(ws.ws_net_paid) >= 100 AND SUM(ws.ws_net_paid) < 500 THEN 'Medium Spend'
            ELSE 'High Spend'
        END AS spend_category,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
), 
income_ranges AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT c.c_customer_id) AS customers_in_range
    FROM 
        income_band ib
    LEFT JOIN 
        customer_demographics cd ON (
            cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
        )
    LEFT JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    ia.c_customer_sk,
    ia.cd_gender,
    ia.cd_marital_status,
    ia.total_spent,
    ia.orders_count,
    ia.spend_category,
    ir.ib_income_band_sk,
    ir.customers_in_range,
    CASE 
        WHEN ir.customers_in_range > 0 THEN 'Income Band Active'
        ELSE 'No Customers in Band'
    END AS income_band_status,
    COALESCE(ia.gender_rank, 0) AS customer_rank
FROM 
    income_analysis ia
FULL OUTER JOIN 
    income_ranges ir ON (ia.total_spent BETWEEN ir.ib_lower_bound AND ir.ib_upper_bound)
WHERE 
    (ia.total_spent IS NOT NULL OR ir.customers_in_range IS NOT NULL)
ORDER BY 
    ia.total_spent DESC NULLS LAST, 
    ir.ib_lower_bound ASC;
