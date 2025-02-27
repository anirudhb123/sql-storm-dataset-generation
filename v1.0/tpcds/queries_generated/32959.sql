
WITH RECURSIVE income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_ranges ir ON ib.ib_income_band_sk > ir.ib_income_band_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
store_sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS sales_count
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
ranked_customers AS (
    SELECT 
        cs.*,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS gender_rank
    FROM 
        customer_summary cs
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_orders,
        rc.total_spent,
        rc.last_order_date,
        i.ir_income_band_sk,
        i.ib_lower_bound,
        i.ib_upper_bound
    FROM 
        ranked_customers rc
    JOIN 
        income_ranges i ON rc.total_spent BETWEEN i.ib_lower_bound AND i.ib_upper_bound
    WHERE 
        rc.gender_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_spent,
    tc.ir_income_band_sk,
    COALESCE(ss.total_sales, 0) AS store_sales
FROM 
    top_customers tc
LEFT JOIN 
    store_sales_summary ss ON tc.c_customer_sk = ss.ss_store_sk
WHERE 
    tc.last_order_date > (SELECT MIN(d_date) FROM date_dim WHERE d_year = 2023)
ORDER BY 
    tc.total_spent DESC;
