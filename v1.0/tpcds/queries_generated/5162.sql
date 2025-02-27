
WITH RankedReturns AS (
    SELECT 
        sr.store_sk,
        SUM(sr.return_quantity) AS total_returned_quantity,
        SUM(sr.return_amt) AS total_returned_amt,
        COUNT(DISTINCT sr.ticket_number) AS total_returned_count
    FROM 
        store_returns sr
    JOIN 
        date_dim d ON sr.returned_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        sr.store_sk
),
StorePerformance AS (
    SELECT 
        s.store_sk,
        s.store_name,
        COALESCE(rr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rr.total_returned_amt, 0) AS total_returned_amt,
        COALESCE(rr.total_returned_count, 0) AS total_returned_count,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        store s
    LEFT JOIN 
        RankedReturns rr ON s.store_sk = rr.store_sk
    LEFT JOIN 
        web_sales ws ON s.store_sk = ws.ws_store_sk
    GROUP BY 
        s.store_sk, s.store_name
),
PerformanceRank AS (
    SELECT 
        sp.store_sk,
        sp.store_name,
        sp.total_returned_quantity,
        sp.total_returned_amt,
        sp.total_returned_count,
        sp.total_sales,
        RANK() OVER (ORDER BY sp.total_sales DESC) AS sales_rank,
        RANK() OVER (ORDER BY sp.total_returned_amt DESC) AS returns_rank
    FROM 
        StorePerformance sp
)
SELECT 
    p.store_sk,
    p.store_name,
    p.total_sales,
    p.total_returned_quantity,
    p.total_returned_amt,
    p.total_returned_count,
    p.sales_rank,
    p.returns_rank
FROM 
    PerformanceRank p
WHERE 
    p.sales_rank <= 10 OR p.returns_rank <= 10
ORDER BY 
    p.sales_rank, p.returns_rank;
