
WITH sales_data AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid_inc_tax) AS total_net_sales,
        d.d_year,
        d.d_month_seq
    FROM 
        store_sales s
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        s.ss_item_sk, d.d_year, d.d_month_seq
), 
customer_data AS (
    SELECT 
        c.c_customer_sk,
        MAX(cd.cd_income_band_sk) AS max_income_band,
        COUNT(DISTINCT c.c_customer_id) AS total_customers
    FROM 
        customer c
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    sd.total_quantity,
    sd.total_net_sales,
    cd.max_income_band,
    cd.total_customers
FROM 
    sales_data sd
JOIN 
    customer_data cd ON sd.ss_item_sk = cd.c_customer_sk
ORDER BY 
    sd.total_net_sales DESC
LIMIT 100;
