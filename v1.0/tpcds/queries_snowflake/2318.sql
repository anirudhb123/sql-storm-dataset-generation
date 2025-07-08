
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_credit_rating IN ('High', 'Medium')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, cd.cd_dep_count
),
SalesRanking AS (
    SELECT 
        cs.*,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSummary cs
),
IncomeBracket AS (
    SELECT 
        h.hd_demo_sk,
        CASE 
            WHEN h.hd_income_band_sk IS NOT NULL THEN 
                (SELECT CONCAT(ib.ib_lower_bound, '-', ib.ib_upper_bound) 
                 FROM income_band ib 
                 WHERE ib.ib_income_band_sk = h.hd_income_band_sk)
            ELSE 'Unknown'
        END AS income_band
    FROM 
        household_demographics h
)
SELECT 
    sr.sales_rank,
    sr.c_customer_sk,
    sr.c_first_name,
    sr.c_last_name,
    sr.cd_gender,
    sr.cd_marital_status,
    sr.total_sales,
    COALESCE(ib.income_band, 'Not Available') AS income_band
FROM 
    SalesRanking sr
LEFT JOIN 
    IncomeBracket ib ON sr.c_customer_sk = ib.hd_demo_sk
WHERE 
    sr.total_sales > 1000
ORDER BY 
    sr.sales_rank, sr.total_sales DESC
LIMIT 10;
