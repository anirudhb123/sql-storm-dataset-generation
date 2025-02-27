
WITH regional_sales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        AVG(ss.ss_net_paid) AS average_transaction_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_net_paid) DESC) AS state_rank
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_state IS NOT NULL
    GROUP BY 
        s.s_store_id, s.s_state
), demographic_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COALESCE(NULLIF(ROUND(CAST(cd.cd_purchase_estimate AS DECIMAL(10, 2)) / NULLIF(cd.cd_dep_count, 0), 2), 0), 0) AS avg_purchase_per_dep,
        DENSE_RANK() OVER (ORDER BY cd.cd_credit_rating) AS credit_rank
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        c.c_birth_year IS NOT NULL
), complex_calculations AS (
    SELECT 
        d.c_customer_sk,
        d.cd_gender,
        CASE 
            WHEN avg_purchase_per_dep > 1000 THEN 'High Value'
            WHEN avg_purchase_per_dep <= 1000 AND avg_purchase_per_dep > 0 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        r.total_sales
    FROM 
        demographic_info d
    LEFT JOIN 
        regional_sales r ON d.c_customer_sk = r.s_store_id
), final_results AS (
    SELECT 
        customer_value,
        COUNT(*) AS customer_count,
        SUM(total_sales) AS total_revenue
    FROM 
        complex_calculations
    GROUP BY 
        customer_value
)
SELECT 
    cr.customer_value,
    cr.customer_count,
    cr.total_revenue,
    CASE 
        WHEN cr.customer_value = 'High Value' THEN cr.total_revenue / NULLIF(cr.customer_count, 0)
        ELSE 0
    END AS avg_revenue_high,
    CASE 
        WHEN cr.customer_value = 'Medium Value' THEN cr.total_revenue / NULLIF(cr.customer_count, 0)
        ELSE 0
    END AS avg_revenue_medium,
    CASE 
        WHEN cr.customer_value = 'Low Value' THEN cr.total_revenue / NULLIF(cr.customer_count, 0)
        ELSE 0
    END AS avg_revenue_low
FROM 
    final_results cr
ORDER BY 
    customer_value DESC;
