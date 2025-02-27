
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss.store_sk,
        SUM(ss.net_profit) AS total_profit,
        COUNT(ss.ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss.net_profit) DESC) AS rank
    FROM 
        store_sales ss
    GROUP BY 
        ss.store_sk
), 
high_income_customers AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        hd.hd_income_band_sk IS NOT NULL
), 
store_average_profit AS (
    SELECT 
        ss.store_sk,
        AVG(ss.net_profit) AS avg_profit
    FROM 
        store_sales ss       
    GROUP BY 
        ss.store_sk
),
recent_high_value_returns AS (
    SELECT 
        wr.web_page_sk,
        SUM(wr.return_amt_inc_tax) AS total_return,
        COUNT(wr.return_number) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.returned_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        wr.web_page_sk
)
SELECT 
    s.s_store_name,
    s.s_city,
    sh.total_profit,
    sh.total_sales,
    COALESCE(sp.avg_profit, 0) AS store_avg_profit,
    COALESCE(rh.total_return, 0) AS recent_total_return
FROM 
    store s
LEFT JOIN 
    sales_hierarchy sh ON s.s_store_sk = sh.store_sk
LEFT JOIN 
    store_average_profit sp ON s.s_store_sk = sp.store_sk
LEFT JOIN 
    recent_high_value_returns rh ON s.s_store_sk = rh.web_page_sk
WHERE 
    sh.rank = 1
    OR EXISTS (
        SELECT 1 
        FROM high_income_customers hic 
        WHERE hic.cd_demo_sk IN (
            SELECT ss.bill_cdemo_sk 
            FROM store_sales ss 
            WHERE ss.store_sk = s.s_store_sk
        )
    )
ORDER BY 
    sh.total_profit DESC, 
    s.s_store_name;
