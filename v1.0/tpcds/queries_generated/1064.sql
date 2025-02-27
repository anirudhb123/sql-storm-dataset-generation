
WITH sales_summary AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        AVG(ss.ss_ext_discount_amt) AS average_discount
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(d.d_date_sk) 
                               FROM date_dim d 
                               WHERE d.d_year = 2023 AND d.d_month_seq < 10)
    GROUP BY 
        s.s_store_id, s.s_store_name
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
),
ranked_sales AS (
    SELECT 
        store_id,
        store_name,
        total_sales,
        transaction_count,
        average_discount,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    ss.total_sales,
    ss.transaction_count,
    ss.average_discount,
    rs.sales_rank,
    COALESCE(NULLIF(cs.total_spent, 0), 'No purchases') AS total_spent_description
FROM 
    customer_summary cs
JOIN 
    ranked_sales rs ON cs.purchase_count > 0
LEFT JOIN 
    sales_summary ss ON ss.s_store_id = (
        SELECT 
            s.s_store_id 
        FROM 
            store s 
        JOIN 
            store_sales ss2 ON s.s_store_sk = ss2.ss_store_sk 
        WHERE 
            ss2.ss_customer_sk = cs.c_customer_sk 
        ORDER BY 
            ss2.ss_sold_date_sk DESC 
        LIMIT 1
    )
WHERE 
    cs.purchase_count > 0 OR rs.sales_rank IS NULL
ORDER BY 
    total_spent DESC, sales_rank;
