
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        web_site_sk, 
        net_profit 
    FROM 
        RankedSales 
    WHERE 
        rank <= 5
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk, 
        COALESCE(ca.ca_city, 'Unknown') as city, 
        COUNT(DISTINCT c.c_customer_id) as customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk 
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
),
JoinedData AS (
    SELECT 
        ts.web_site_sk, 
        ts.net_profit, 
        ad.city, 
        ad.customer_count 
    FROM 
        TopSales ts
    JOIN 
        AddressDetails ad ON ts.web_site_sk = ad.ca_address_sk
)
SELECT 
    jd.web_site_sk,
    jd.city,
    jd.customer_count,
    jd.net_profit,
    CASE 
        WHEN jd.net_profit > 10000 THEN 'High Profit'
        WHEN jd.net_profit IS NULL THEN 'Profit Not Available'
        ELSE 'Low Profit'
    END as profit_status,
    CASE WHEN jd.customer_count IS NULL THEN 'No Customers' ELSE 'Customers Found' END as customer_status
FROM 
    JoinedData jd
ORDER BY 
    jd.web_site_sk DESC
FETCH FIRST 10 ROWS ONLY;

WITH RecursiveSales AS (
    SELECT 
        ss.ss_customer_sk, 
        SUM(ss.ss_net_profit) as total_net_profit,
        r.r_reason_desc
    FROM 
        store_sales ss
    LEFT JOIN 
        reason r ON r.r_reason_sk = (SELECT cr_reason_sk FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = ss.ss_customer_sk AND cr.cr_return_number = ss.ss_ticket_number)
    GROUP BY 
        ss.ss_customer_sk, r.r_reason_desc
    HAVING 
        SUM(ss.ss_net_profit) IS NOT NULL
),
FinalReview AS (
    SELECT 
        customer_sk, 
        MAX(total_net_profit) as max_profit,
        COUNT(*) as transaction_count
    FROM 
        RecursiveSales
    GROUP BY 
        ss_customer_sk
)
SELECT 
    fr.customer_sk, 
    fr.max_profit, 
    fr.transaction_count,
    CASE 
        WHEN fr.max_profit IS NULL THEN 'No Profit Recorded'
        ELSE 'Profit Recorded'
    END as review_status
FROM 
    FinalReview fr
WHERE 
    fr.transaction_count > 2
ORDER BY 
    fr.transaction_count DESC;
