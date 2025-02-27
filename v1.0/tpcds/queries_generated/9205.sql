
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023 AND 
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
    GROUP BY 
        c.c_customer_id
),
IncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    ss.c_customer_id,
    ss.total_sales,
    ss.transaction_count,
    ss.avg_net_profit,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ib.customer_count
FROM 
    SalesSummary ss
JOIN 
    household_demographics hd ON ss.c_customer_id = hd.hd_demo_sk
JOIN 
    IncomeBands ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
