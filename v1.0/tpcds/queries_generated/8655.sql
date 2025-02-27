
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk, 
        sr.return_time_sk, 
        sr.item_sk, 
        sr.customer_sk, 
        sr.store_sk, 
        sr.return_quantity, 
        sr.return_amt, 
        sr.return_tax, 
        ROW_NUMBER() OVER (PARTITION BY sr.store_sk ORDER BY sr.return_amt DESC) AS rank_return
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = '2023-12-31')
),
TopReturns AS (
    SELECT 
        rr.store_sk, 
        SUM(rr.return_quantity) AS total_return_quantity, 
        SUM(rr.return_amt) AS total_return_amt
    FROM 
        RankedReturns rr
    WHERE 
        rr.rank_return <= 10
    GROUP BY 
        rr.store_sk
),
StoreDetails AS (
    SELECT 
        s.store_sk, 
        s.store_name, 
        s.city, 
        s.state, 
        s.country
    FROM 
        store s
)

SELECT 
    sd.store_name, 
    sd.city, 
    sd.state, 
    sd.country, 
    tr.total_return_quantity, 
    tr.total_return_amt
FROM 
    TopReturns tr
JOIN 
    StoreDetails sd ON tr.store_sk = sd.store_sk
ORDER BY 
    tr.total_return_amt DESC;
