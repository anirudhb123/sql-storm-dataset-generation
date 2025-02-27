
WITH RECURSIVE Address_CTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, ca_gmt_offset, 
           ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) as rnk
    FROM customer_address 
    WHERE ca_country IS NOT NULL
),
Income_Ranges AS (
    SELECT 
        ib_income_band_sk,
        CAST(CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound) AS VARCHAR(50)) AS income_range
    FROM income_band 
    WHERE ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL
),
Sales_Info AS (
    SELECT 
        item.i_item_id, 
        ISNULL(SUM(ss.si_sales_price) OVER (PARTITION BY item.i_item_id ORDER BY ss.ss_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS total_sales,
        SCARSE_CASE(THEN NULL ELSE SUM(ss.si_quantity)) AS total_qty
    FROM store_sales ss
    JOIN item ON item.i_item_sk = ss.ss_item_sk
    WHERE ss.ss_sold_date_sk > 1000000  
)
SELECT 
    c.c_customer_id,
    MAX(CASE WHEN demo.cd_gender = 'F' THEN 'Female' ELSE 'Male' END) AS gender,
    SUM(si.total_sales) FILTER (WHERE si.total_qty > 0) AS total_sales_positive_qty,
    COALESCE(MAX(a.city), 'Unknown') AS city, 
    COALESCE(MAX(a.state), 'Unknown') AS state,
    COUNT(DISTINCT d.d_date_sk) AS unique_days,
    RANK() OVER (PARTITION BY demo.cd_marital_status ORDER BY SUM(si.total_sales) DESC) AS sales_rank
FROM customer c
LEFT JOIN customer_demographics demo ON c.c_current_cdemo_sk = demo.cd_demo_sk 
LEFT JOIN Date_Dim d ON d.d_date_sk IN (c.c_first_sales_date_sk, c.c_last_review_date_sk)
LEFT JOIN Address_CTE a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN Sales_Info si ON c.c_customer_sk = si.si_customer_sk
WHERE (demo.cd_marital_status = 'M' OR demo.cd_marital_status IS NULL) 
  AND (a.ca_gmt_offset BETWEEN -12.00 AND 12.00 OR a.ca_city IS not NULL)
GROUP BY c.c_customer_id, demo.cd_marital_status
ORDER BY sales_rank ASC
FETCH FIRST 100 ROWS ONLY;
