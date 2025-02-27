
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        w.w_warehouse_name AS warehouse_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_paid) AS average_transaction_value
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, w.w_warehouse_name
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(sales_summary.total_net_profit) AS total_net_profit_by_demo
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        sales_summary ON c.c_customer_sk IN (
            SELECT ss.ss_customer_sk FROM store_sales ss WHERE ss.ss_sold_date_sk = sales_summary.sales_year
        )
    GROUP BY 
        cd.cd_gender, hd.hd_income_band_sk
)
SELECT 
    ds.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ds.total_net_profit_by_demo,
    ds.customer_count
FROM 
    demographics_summary ds
JOIN 
    income_band ib ON ds.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ds.cd_gender, ib.ib_lower_bound;
