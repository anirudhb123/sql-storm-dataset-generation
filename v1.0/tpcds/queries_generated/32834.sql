
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_item_sk
),
AddressAgg AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, ca.ca_country
),
DateSales AS (
    SELECT 
        d.d_date_id,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ws_ext_sales_price) AS total_web_sales
    FROM date_dim d
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date_id
),
WindowedSales AS (
    SELECT 
        d.d_date_id,
        d.d_year,
        COALESCE(total_store_sales, 0) AS total_store_sales,
        COALESCE(total_web_sales, 0) AS total_web_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_date_id) AS date_rank
    FROM DateSales d
)
SELECT 
    wa.ca_country,
    ds.d_year,
    SUM(ws.total_sales + cs.total_sales) AS combined_sales,
    AVG(ws.total_sales) AS avg_web_sales,
    SUM(CASE WHEN ws.total_sales IS NULL THEN 0 ELSE 1 END) AS web_sales_records,
    COUNT(*) OVER (PARTITION BY wa.ca_country) AS country_customer_count
FROM AddressAgg wa
LEFT JOIN SalesCTE ws ON wa.c_customer_sk = ws.ws_item_sk
LEFT JOIN SalesCTE cs ON wa.c_customer_sk = cs.cs_item_sk
JOIN WindowedSales ds ON ds.date_rank = ROW_NUMBER() OVER (ORDER BY ds.d_date_id)
WHERE (wa.customer_count > 5 OR wa.ca_country IS NOT NULL)
GROUP BY wa.ca_country, ds.d_year
ORDER BY total_sales DESC, wa.ca_country;
