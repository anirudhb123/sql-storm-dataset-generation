WITH RECURSIVE revenue_cte AS (
    SELECT 
        d.d_year AS year,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year

    UNION ALL

    SELECT 
        year - 1,
        total_revenue * 1.05   
    FROM 
        revenue_cte
    WHERE 
        year > (SELECT MAX(d_year) FROM date_dim)
),
customer_returns AS (
    SELECT 
        c.c_customer_id,
        COUNT(sr.sr_item_sk) AS return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
customer_income AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_id) AS num_customers,
        AVG(CASE 
            WHEN d.d_year = EXTRACT(YEAR FROM cast('2002-10-01 12:34:56' as timestamp)) THEN c.c_birth_year 
            ELSE NULL 
        END) AS avg_birth_year
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    GROUP BY 
        h.hd_income_band_sk
)
SELECT 
    ci.hd_income_band_sk,
    ci.num_customers,
    ci.avg_birth_year,
    coalesce(cr.return_count, 0) AS total_returns,
    coalesce(cr.total_return_amt, 0) AS return_amount,
    r.year,
    r.total_revenue
FROM 
    customer_income ci
LEFT JOIN 
    customer_returns cr ON ci.num_customers > 0
JOIN 
    revenue_cte r ON r.year = EXTRACT(YEAR FROM cast('2002-10-01 12:34:56' as timestamp)) - 1
WHERE 
    ci.hd_income_band_sk IS NOT NULL
ORDER BY 
    ci.hd_income_band_sk;