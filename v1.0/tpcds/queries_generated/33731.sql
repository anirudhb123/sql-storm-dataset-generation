
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_profit) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_net_profit) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
    HAVING 
        SUM(ss_net_profit) > 1000
), 
Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_age_band,
        cd.cd_income_band_sk,
        cb.total_sales
    FROM 
        customer_demographics cd
    JOIN (
        SELECT 
            c_current_cdemo_sk,
            MAX(total_sales) AS total_sales
        FROM 
            Sales_CTE
        GROUP BY 
            c_current_cdemo_sk
    ) cb ON cb.c_current_cdemo_sk = cd.cd_demo_sk
), 
Top_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.total_sales,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        Customer_Demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.sales_rank = 1
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    (SELECT 
        COUNT(*)
     FROM 
        store_returns sr
     WHERE 
        sr.sr_customer_sk = tc.c_customer_sk) AS return_count,
    (SELECT 
        SUM(sr_return_amt)
     FROM 
        store_returns sr 
     WHERE 
        sr.sr_customer_sk = tc.c_customer_sk
    ) AS total_return_amount,
    (SELECT 
        COUNT(DISTINCT sr_ticket_number)
     FROM 
        store_returns sr 
     WHERE 
        sr.sr_customer_sk = tc.c_customer_sk) AS unique_returns
FROM 
    Top_Customers tc
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_income_band_sk IS NOT NULL
ORDER BY 
    tc.total_sales DESC;

