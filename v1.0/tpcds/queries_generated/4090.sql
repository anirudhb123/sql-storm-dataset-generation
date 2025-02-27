
WITH daily_sales AS (
    SELECT 
        d.d_date AS sale_date,
        s.ss_sold_date_sk,
        SUM(s.ss_net_paid_inc_tax) AS total_net_sales,
        COUNT(s.ss_ticket_number) AS total_transactions
    FROM 
        store_sales s 
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date, s.ss_sold_date_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count
    FROM 
        customer_info ci 
    JOIN 
        household_demographics hd ON ci.c_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ds.sale_date,
    ds.total_net_sales,
    ds.total_transactions,
    COALESCE(id.customer_count, 0) AS customer_count,
    RANK() OVER (ORDER BY ds.total_net_sales DESC) AS sales_rank
FROM 
    daily_sales ds
LEFT JOIN 
    income_distribution id ON ds.ss_sold_date_sk = id.ib_income_band_sk
WHERE 
    ds.total_net_sales > 5000
ORDER BY 
    ds.sale_date;
