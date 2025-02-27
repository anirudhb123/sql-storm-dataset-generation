
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_credit_rating,
        GREATEST(COALESCE(CD.cd_purchase_estimate, 0), 1000) AS purchase_estimate_adjusted,
        CASE 
            WHEN CD.cd_dep_count IS NULL THEN 'Unknown'
            ELSE CASE 
                WHEN CD.cd_dep_count < 2 THEN 'Single'
                WHEN CD.cd_dep_count BETWEEN 2 AND 4 THEN 'Family'
                ELSE 'Large Family'
            END
        END AS household_type
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics AS CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk > 100000  -- Arbitrary date logic
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, CD.cd_gender, 
        CD.cd_marital_status, CD.cd_credit_rating, CD.cd_dep_count
),
top_customers AS (
    SELECT 
        customer_cstats.*,
        RANK() OVER (PARTITION BY customer_cstats.cd_gender ORDER BY customer_cstats.total_profit DESC) AS gender_profit_rank
    FROM 
        customer_stats customer_cstats
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_profit, 
    tc.order_count, 
    tc.cd_gender, 
    tc.household_type,
    CASE 
        WHEN tc.gender_profit_rank <= 5 THEN 'Top Performer'
        ELSE 'Average Performer'
    END AS performance_label
FROM 
    top_customers AS tc
WHERE 
    tc.gender_profit_rank <= 10 AND 
    tc.purchase_estimate_adjusted > 2000
ORDER BY 
    tc.total_profit DESC;
