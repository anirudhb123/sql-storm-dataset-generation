
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_transaction_value,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        CA.ca_city,
        CA.ca_state
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, CA.ca_city, CA.ca_state
),
income_summary AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(cs.c_customer_sk) AS customer_count,
        AVG(total_sales) AS avg_sales_per_customer
    FROM 
        customer_summary cs
    JOIN 
        income_band ib ON cs.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    is.customer_count,
    is.avg_sales_per_customer,
    ROW_NUMBER() OVER (ORDER BY is.avg_sales_per_customer DESC) AS rank
FROM 
    income_band ib
LEFT JOIN 
    income_summary is ON ib.ib_income_band_sk = is.ib_income_band_sk
ORDER BY 
    rank;
