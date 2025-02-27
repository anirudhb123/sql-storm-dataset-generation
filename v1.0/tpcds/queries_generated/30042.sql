
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ss.sold_date_sk,
        ss_item_sk,
        ss_quantity,
        ss_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk) as rn
    FROM store_sales ss
    WHERE ss.sold_date_sk BETWEEN 2458856 AND 2458890
),
Income_Bracket AS (
    SELECT 
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
Total_Sales AS (
    SELECT 
        S.sold_date_sk,
        SUM(S.ss_quantity * S.ss_sales_price) AS total_sales
    FROM Sales_CTE S
    GROUP BY S.sold_date_sk
),
Customer_Address AS (
    SELECT 
        ca.ca_zip,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_zip
),
Sales_Performance AS (
    SELECT 
        CB.hd_income_band_sk,
        CB.customer_count,
        TA.total_sales,
        CA.unique_customers
    FROM Income_Bracket CB
    LEFT JOIN Total_Sales TA ON CB.hd_income_band_sk = TA.sold_date_sk
    LEFT JOIN Customer_Address CA ON CA.ca_zip IS NOT NULL
)
SELECT 
    SP.hd_income_band_sk,
    SP.customer_count,
    COALESCE(SUM(SP.total_sales), 0) AS total_sales_generated,
    COALESCE(SP.unique_customers, 0) AS unique_customers,
    (CASE 
         WHEN SP.customer_count = 0 THEN NULL
         ELSE (SUM(SP.total_sales)/SP.customer_count) 
     END) AS avg_sales_per_customer
FROM Sales_Performance SP
GROUP BY SP.hd_income_band_sk, SP.customer_count, SP.unique_customers
HAVING SUM(SP.total_sales) > 10000
ORDER BY avg_sales_per_customer DESC
```
