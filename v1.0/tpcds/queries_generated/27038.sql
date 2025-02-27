
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT wr.wr_order_number) AS web_returns_count,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_count,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amount,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_sales_profit,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_sales_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
IncomeBandSummary AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(CASE WHEN cs.total_web_sales_profit > 0 THEN 1 ELSE 0 END) AS web_sales_customers,
        SUM(CASE WHEN cs.total_store_sales_profit > 0 THEN 1 ELSE 0 END) AS store_sales_customers,
        SUM(cs.total_web_sales_profit) AS total_web_sales,
        SUM(cs.total_store_sales_profit) AS total_store_sales
    FROM 
        CustomerStats cs
    JOIN 
        household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(web_sales_customers, 0) AS web_sales_customers,
    COALESCE(store_sales_customers, 0) AS store_sales_customers,
    COALESCE(total_web_sales, 0) AS total_web_sales,
    COALESCE(total_store_sales, 0) AS total_store_sales,
    (COALESCE(total_web_sales, 0) + COALESCE(total_store_sales, 0)) AS total_sales
FROM 
    IncomeBandSummary ib
ORDER BY 
    ib.ib_income_band_sk;
