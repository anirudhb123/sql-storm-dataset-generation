
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_division_name,
        1 AS level
    FROM 
        store
    WHERE 
        s_closed_date_sk IS NULL
    UNION ALL
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_division_name,
        level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        store s ON sh.s_store_sk = s.s_store_sk
    WHERE 
        s.s_closed_date_sk IS NULL
), 
date_range AS (
    SELECT 
        d_year, 
        d_month_seq, 
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        date_dim
    JOIN 
        web_sales ON d_date_sk = ws_sold_date_sk
    WHERE 
        d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        d_year, d_month_seq
),
customer_retention AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_returned_amt
    FROM
        customer c
    LEFT JOIN
        web_returns wr ON c.c_customer_sk = wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    s.hierarchy AS store_hierarchy,
    dr.d_year,
    dr.d_month_seq,
    dr.total_orders,
    dr.total_sales,
    cr.total_returns,
    cr.total_returned_amt,
    CASE 
        WHEN dr.total_sales > 100000 THEN 'High Revenue'
        WHEN dr.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    sales_hierarchy s
JOIN 
    date_range dr ON s.s_store_sk = dr.d_month_seq
LEFT JOIN 
    customer_retention cr ON cr.c_customer_sk = s.s_store_sk
ORDER BY 
    dr.d_year, 
    dr.d_month_seq, 
    revenue_category;
