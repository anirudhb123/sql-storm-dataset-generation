
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopReturners AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_return_value,
        RANK() OVER (ORDER BY cr.total_return_value DESC) AS rank
    FROM 
        CustomerReturns cr
),
HighIncomeCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ib.ib_upper_bound IS NOT NULL AND ib.ib_upper_bound > 100000
),
ReturnSummary AS (
    SELECT 
        tr.sr_customer_sk,
        tr.total_returns,
        th.rank,
        hic.c_first_name,
        hic.c_last_name,
        hic.buy_potential
    FROM 
        TopReturners tr
    INNER JOIN 
        HighIncomeCustomers hic ON tr.sr_customer_sk = hic.c_customer_sk
)
SELECT 
    rs.c_first_name,
    rs.c_last_name,
    rs.total_returns,
    rs.rank,
    CASE 
        WHEN rs.total_returns > 10 THEN 'Frequent Returner'
        ELSE 'Occasional Returner'
    END AS returner_type,
    (SELECT AVG(total_return_value) 
     FROM CustomerReturns 
     WHERE total_returns > 5) AS avg_high_value_returners,
    (SELECT COUNT(*)
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = rs.sr_customer_sk AND ss.ss_sold_date_sk BETWEEN 
     (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
     AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)) AS recent_sales_count
FROM 
    ReturnSummary rs
ORDER BY 
    rs.rank ASC, 
    rs.total_returns DESC;
