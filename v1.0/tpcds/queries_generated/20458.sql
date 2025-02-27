
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.net_paid AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.sold_date_sk DESC) AS rank_sales
    FROM web_sales ws
    WHERE ws.sold_date_sk IN (
        SELECT DISTINCT sd.d_date_sk 
        FROM date_dim sd 
        WHERE sd.d_year = 2023 AND sd.d_weekend = '1'
    )
),
AggregateReturns AS (
    SELECT 
        wr.w_web_page_sk,
        SUM(wr.return_amt) AS total_returns,
        COUNT(*) AS return_count
    FROM web_returns wr
    WHERE wr.returned_date_sk IN (
        SELECT sd.d_date_sk 
        FROM date_dim sd 
        WHERE sd.d_month_seq BETWEEN 1 AND 6
    )
    GROUP BY wr.w_web_page_sk
),
CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN ca.ca_zip IS NULL THEN 'ZIP Missing' 
            ELSE ca.ca_zip 
        END AS zip_code_status,
        COALESCE(c.c_last_name, 'Unknown') AS last_name
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
ReturnStatistics AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        SUM(CASE 
                WHEN sr.return_quantity > 0 THEN sr.return_quantity 
                ELSE 0 
            END) AS total_quantity_returned,
        AVG(sr.return_amt) AS average_return_amount
    FROM store_returns sr
    WHERE sr.returned_date_sk IS NOT NULL
    GROUP BY sr.returned_date_sk, sr.return_time_sk
)
SELECT 
    c.city AS address_city,
    COUNT(DISTINCT r.rank_sales) AS distinct_sales_rank,
    SUM(COALESCE(a.total_returns, 0)) AS total_returns_amount,
    AVG(d.average_return_amount) AS avg_return_amount_per_day,
    CASE 
        WHEN COUNT(DISTINCT ca.address_sk) > 5 THEN 'Diverse Addresses' 
        ELSE 'Limited Addresses' 
    END AS address_diversity
FROM CustomerAddressDetails ca
JOIN RankedSales r ON r.web_site_sk = ca.ca_address_sk
LEFT JOIN AggregateReturns a ON a.w_web_page_sk = ca.ca_address_sk
LEFT JOIN ReturnStatistics d ON d.returned_date_sk = ca.ca_address_sk
WHERE ca.city IS NOT NULL
AND ca.state IN ('NY', 'CA') 
GROUP BY c.city
HAVING SUM(COALESCE(r.total_sales, 0)) > 10000 
   OR COUNT(DISTINCT ca.city) = 0
ORDER BY address_diversity, address_city DESC;
