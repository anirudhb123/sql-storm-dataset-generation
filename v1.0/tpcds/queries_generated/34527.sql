
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss.store_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ss.store_sk, ss_sold_date_sk
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND (hd.hd_income_band_sk IS NULL OR hd.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound < 50000))
),
promotion_stats AS (
    SELECT 
        p.p_promo_name,
        COUNT(ps.ws_order_number) AS total_promo_sales,
        SUM(ps.ws_ext_sales_price) AS promo_sales_amount
    FROM 
        promotion p
    JOIN 
        web_sales ps ON p.p_promo_sk = ps.ws_promo_sk
    GROUP BY 
        p.p_promo_name
),
date_range AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        ROW_NUMBER() OVER (ORDER BY d.d_date DESC) AS day_rank
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)

SELECT 
    s.store_sk,
    s.total_sales,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.hd_income_band_sk,
    ps.promo_sales_amount,
    dr.d_date
FROM 
    sales_cte s
LEFT JOIN 
    customer_info ci ON s.store_sk = ci.c_customer_sk
LEFT JOIN 
    promotion_stats ps ON ps.total_promo_sales > 50
INNER JOIN 
    date_range dr ON dr.day_rank <= 30
WHERE 
    s.sales_rank = 1
    AND (ci.cd_gender IS NULL OR ci.cd_gender = 'F')
ORDER BY 
    s.total_sales DESC, 
    ci.c_last_name ASC;
