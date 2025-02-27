
WITH 
    RankedSales AS (
        SELECT 
            ss_store_sk,
            ss_item_sk,
            SUM(ss_sales_price) AS total_sales,
            ROW_NUMBER() OVER(PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS rank_sales
        FROM 
            store_sales
        WHERE 
            ss_sold_date_sk BETWEEN 1 AND 365
        GROUP BY 
            ss_store_sk, ss_item_sk
    ),
    NullHandling AS (
        SELECT 
            cs_bill_customer_sk AS customer_sk,
            cs_item_sk,
            COALESCE(SUM(cs_net_profit), 0) AS total_net_profit
        FROM 
            catalog_sales
        GROUP BY 
            cs_bill_customer_sk, cs_item_sk
    )
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(RS.total_sales, 0) AS total_store_sales,
    NH.total_net_profit,
    DENSE_RANK() OVER(ORDER BY COALESCE(RS.total_sales, 0) DESC) AS sales_rank,
    CASE 
        WHEN C.c_birth_year IS NULL THEN 'Unknown' 
        ELSE CONCAT('Year: ', CAST(C.c_birth_year AS CHAR))
    END AS birthday_info,
    (SELECT COUNT(*) FROM store WHERE s_country = 'USA') AS usa_store_count,
    (SELECT COUNT(DISTINCT ws_web_site_sk) FROM web_sales WHERE ws_item_sk = RS.ss_item_sk) AS web_sales_count
FROM 
    customer c
LEFT JOIN 
    RankedSales RS ON c.c_customer_sk = RS.ss_store_sk
LEFT JOIN 
    NullHandling NH ON c.c_customer_sk = NH.customer_sk AND RS.ss_item_sk = NH.cs_item_sk
LEFT JOIN 
    date_dim d ON d.d_date_sk = RS.ss_sold_date_sk
WHERE 
    (C.c_preferred_cust_flag = 'Y' OR C.c_birth_month BETWEEN 1 AND 6)
    AND (C.c_email_address LIKE '%@example.com' OR C.c_current_addr_sk IS NOT NULL)
ORDER BY 
    total_store_sales DESC NULLS LAST
LIMIT 100;
