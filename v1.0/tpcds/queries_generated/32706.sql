
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
), 
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'No Dependents'
            ELSE CONCAT('Dependents: ', cd.cd_dep_count)
        END AS dependents_info
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), 
returns_summary AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_items_returned
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.hd_buy_potential,
    SUM(ss.total_sales) AS total_sales_contribution,
    rs.total_returns,
    rs.total_return_amount,
    rs.total_items_returned,
    CASE 
        WHEN rs.total_returns > 5 THEN 'High Return Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    customer_details cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.ss_store_sk
LEFT JOIN 
    returns_summary rs ON cs.c_customer_sk = rs.sr_customer_sk
WHERE 
    cs.cd_income_band_sk IS NOT NULL
GROUP BY 
    cs.c_first_name, cs.c_last_name, cs.cd_gender, cs.hd_buy_potential, rs.total_returns, rs.total_return_amount, rs.total_items_returned
HAVING 
    SUM(ss.total_sales) > 1000
ORDER BY 
    total_sales_contribution DESC
LIMIT 10;
