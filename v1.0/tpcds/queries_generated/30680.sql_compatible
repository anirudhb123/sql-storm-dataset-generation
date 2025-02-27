
WITH RECURSIVE sales_summary AS (
    SELECT 
        c_customer_sk, 
        SUM(ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss_ticket_number) AS purchase_count,
        RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 
              AND d_moy BETWEEN 1 AND 6
        )
    GROUP BY 
        c_customer_sk
),
top_customers AS (
    SELECT 
        cu.c_customer_id,
        cu.c_first_name,
        cu.c_last_name,
        ss.total_spent,
        ss.purchase_count
    FROM 
        customer cu
    JOIN 
        sales_summary ss ON cu.c_customer_sk = ss.c_customer_sk
    WHERE 
        ss.rank <= 100
),
customer_demographics AS (
    SELECT 
        cd.*, 
        CASE
            WHEN cd_dep_count > 2 THEN 'Large Family'
            WHEN cd_dep_count = 2 THEN 'Medium Family'
            ELSE 'Small Family'
        END AS family_size,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    tc.c_customer_id, 
    tc.c_first_name, 
    tc.c_last_name,
    cd.cd_gender,
    cd.family_size,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_net_paid) AS total_amount,
    AVG(cs.cs_net_paid) AS average_order_value,
    MAX(cs.cs_net_paid) AS max_order_value,
    MIN(cs.cs_net_paid) AS min_order_value,
    CASE 
        WHEN COUNT(DISTINCT cs.cs_order_number) > 0 THEN 
            SUM(cs.cs_net_paid) / COUNT(DISTINCT cs.cs_order_number) 
        ELSE 0 
    END AS avg_spent_per_order
FROM 
    top_customers tc
LEFT JOIN 
    catalog_sales cs ON tc.c_customer_id = cs.cs_bill_customer_sk
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
GROUP BY 
    tc.c_customer_id, 
    tc.c_first_name, 
    tc.c_last_name,
    cd.cd_gender,
    cd.family_size
HAVING 
    SUM(cs.cs_net_paid) > 1000
ORDER BY 
    total_amount DESC;
