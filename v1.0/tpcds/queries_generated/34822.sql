
WITH RECURSIVE top_customers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        SUM(ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name
    HAVING 
        SUM(ss_net_paid) > 1000
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
monthly_sales AS (
    SELECT 
        d_year, 
        d_month_seq, 
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d_year, d_month_seq
),
sales_ranks AS (
    SELECT 
        *, 
        RANK() OVER (PARTITION BY d_year ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        RANK() OVER (PARTITION BY d_year ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM 
        monthly_sales
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    s.total_spent, 
    m.d_year, 
    m.d_month_seq, 
    m.total_web_sales, 
    m.total_catalog_sales, 
    m.total_store_sales,
    CASE 
        WHEN m.total_web_sales > COALESCE(m.total_catalog_sales, 0) AND m.total_web_sales > COALESCE(m.total_store_sales, 0) THEN 'Web Sales Leader'
        WHEN m.total_catalog_sales > COALESCE(m.total_web_sales, 0) AND m.total_catalog_sales > COALESCE(m.total_store_sales, 0) THEN 'Catalog Sales Leader'
        WHEN m.total_store_sales > COALESCE(m.total_web_sales, 0) AND m.total_store_sales > COALESCE(m.total_catalog_sales, 0) THEN 'Store Sales Leader'
        ELSE 'Sales Equal'
    END AS sales_lead_status,
    r.web_sales_rank,
    r.catalog_sales_rank,
    r.store_sales_rank
FROM 
    top_customers c
JOIN 
    sales_ranks r ON c.c_customer_sk = r.top_customer
JOIN 
    monthly_sales m ON r.d_year = m.d_year AND r.d_month_seq = m.d_month_seq
WHERE 
    r.web_sales_rank <= 5 OR r.catalog_sales_rank <= 5 OR r.store_sales_rank <= 5
ORDER BY 
    c.total_spent DESC, m.d_year DESC, m.d_month_seq DESC;
