
WITH RankedSales AS (
    SELECT 
        ss.store_sk,
        ss.customer_sk,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY ss.sales_price DESC) AS sales_rank,
        SUM(ss.ext_sales_price) OVER (PARTITION BY ss.store_sk) AS total_sales,
        COUNT(*) OVER (PARTITION BY ss.store_sk) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.customer_sk = c.customer_sk
    WHERE 
        c.birth_month = 12 AND 
        (c.current_hdemo_sk IS NOT NULL OR c.current_addr_sk IS NULL)
),
AddressStats AS (
    SELECT 
        ca.city,
        COUNT(DISTINCT c.customer_id) AS customer_count,
        AVG(cd.dep_count) AS avg_dependency
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.current_addr_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city
),
DistinctReturns AS (
    SELECT 
        sr.returned_date_sk, 
        COUNT(DISTINCT sr.return_ticket_number) AS distinct_return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk
),
SalesAndReturns AS (
    SELECT 
        ss.store_sk,
        COUNT(DISTINCT sr.return_ticket_number) AS total_returns,
        SUM(ss.ext_sales_price) AS total_sales,
        AVG(DISTINCT sr.return_quantity) AS avg_return_quantity
    FROM 
        store_sales ss
    LEFT JOIN 
        store_returns sr ON ss.ticket_number = sr.ticket_number
    GROUP BY 
        ss.store_sk
),
FinalStats AS (
    SELECT 
        r.store_sk,
        r.total_sales,
        r.total_returns,
        r.avg_return_quantity,
        a.customer_count,
        a.avg_dependency
    FROM 
        SalesAndReturns r
    JOIN 
        AddressStats a ON r.store_sk = a.city
)
SELECT 
    f.store_sk,
    f.total_sales,
    CASE 
        WHEN f.total_returns IS NULL THEN 0 
        ELSE f.total_returns 
    END AS total_returns,
    f.customer_count,
    f.avg_dependency,
    CASE 
        WHEN f.avg_return_quantity IS NULL THEN 'No Returns' 
        ELSE CAST(f.avg_return_quantity AS VARCHAR)
    END AS avg_return_quantity_string
FROM 
    FinalStats f
ORDER BY 
    f.total_sales DESC;
