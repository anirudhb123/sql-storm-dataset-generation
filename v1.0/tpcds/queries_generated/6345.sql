
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        sr.return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr.item_sk ORDER BY sr.return_amt DESC) AS rnk
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.customer_sk = c.customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    WHERE 
        cd.gender = 'F' 
        AND cd.education_status LIKE '%Bachelor%'
),
TotalReturns AS (
    SELECT 
        rr.returned_date_sk,
        SUM(rr.return_quantity) AS total_quantity,
        SUM(rr.return_amt) AS total_amt,
        SUM(rr.return_tax) AS total_tax,
        COUNT(rr.return_quantity) AS total_returns
    FROM 
        RankedReturns rr
    WHERE 
        rr.rnk <= 3
    GROUP BY 
        rr.returned_date_sk
)
SELECT 
    dd.date,
    tr.total_quantity,
    tr.total_amt,
    tr.total_tax,
    tr.total_returns
FROM 
    date_dim dd
LEFT JOIN 
    TotalReturns tr ON dd.date_sk = tr.returned_date_sk
WHERE 
    dd.month_seq = (SELECT MAX(month_seq) FROM date_dim WHERE year = 2023)
ORDER BY 
    dd.date;
