
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        'Top Level' AS hierarchy_level
    FROM
        customer c
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
    
    UNION ALL
    
    SELECT
        sr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        'Returned Sales' AS hierarchy_level
    FROM
        store_returns sr
    JOIN customer c ON c.c_customer_sk = sr.sr_customer_sk
    WHERE
        sr.sr_return_quantity > 0
),
sales_summary AS (
    SELECT
        c.c_cdemo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_web_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM
        web_sales ws
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_cdemo_sk
),
monthly_sales AS (
    SELECT
        d.d_month_seq,
        SUM(ws.ws_net_paid_inc_tax) AS monthly_revenue
    FROM
        web_sales ws
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        d.d_month_seq
),
top_months AS (
    SELECT
        d.d_month_seq,
        monthly_revenue,
        RANK() OVER (ORDER BY monthly_revenue DESC) AS revenue_rank
    FROM
        monthly_sales
)

SELECT
    h.c_first_name,
    h.c_last_name,
    h.c_birth_year,
    COALESCE(s.total_web_sales, 0) AS total_web_sales,
    COALESCE(s.total_net_web_sales, 0) AS total_net_net_sales,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    CASE
        WHEN tm.revenue_rank <= 3 THEN 'Top 3 Months'
        ELSE 'Other Months'
    END AS revenue_category
FROM
    sales_hierarchy h
LEFT JOIN sales_summary s ON h.c_customer_sk = s.c_cdemo_sk
LEFT JOIN top_months tm ON tm.d_month_seq = (SELECT MAX(d_month_seq) FROM monthly_sales)
ORDER BY
    h.c_last_name, h.c_first_name;
