
WITH RECURSIVE Customer_Hierarchy AS (
    SELECT c_customer_sk, c_current_cdemo_sk, c_first_name, c_last_name, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_current_cdemo_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer AS c
    JOIN Customer_Hierarchy AS ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
Income_Ranges AS (
    SELECT ib_income_band_sk, 
           ib_lower_bound || ' - ' || ib_upper_bound AS income_range
    FROM income_band
),
Sales_Summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(*) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
Customer_Income AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(i.income_range, 'Unknown') AS income_range,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.transaction_count, 0) AS transaction_count,
        CASE 
            WHEN COALESCE(ss.total_sales, 0) > 1000 THEN 'High Value'
            WHEN COALESCE(ss.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM Customer_Hierarchy AS ch
    LEFT JOIN household_demographics AS hd ON ch.c_current_cdemo_sk = hd.hd_demo_sk
    LEFT JOIN Income_Ranges AS i ON hd.hd_income_band_sk = i.ib_income_band_sk
    LEFT JOIN Sales_Summary AS ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.income_range,
    ci.total_sales,
    ci.transaction_count,
    ci.customer_value
FROM Customer_Income AS ci
WHERE ci.total_sales IS NOT NULL
ORDER BY ci.total_sales DESC
LIMIT 50;
