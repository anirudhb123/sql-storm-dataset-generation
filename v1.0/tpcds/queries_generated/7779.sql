
WITH RankedReturns AS (
    SELECT 
        sr.refund_reason,
        SUM(sr.return_quantity) AS total_return_quantity,
        SUM(sr.return_amt) AS total_return_amt,
        SUM(sr.return_tax) AS total_return_tax,
        COUNT(DISTINCT sr.ticket_number) AS unique_order_count,
        ROW_NUMBER() OVER (PARTITION BY sr.return_reason ORDER BY SUM(sr.return_amt) DESC) AS rank
    FROM 
        store_returns sr 
    JOIN 
        customer_demographics cd ON sr.cdemo_sk = cd.cd_demo_sk 
    JOIN 
        date_dim dd ON sr.returned_date_sk = dd.d_date_sk 
    WHERE 
        dd.d_year = 2022 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F' 
    GROUP BY 
        sr.refund_reason
)
SELECT 
    rr.refund_reason,
    rr.total_return_quantity,
    rr.total_return_amt,
    rr.total_return_tax,
    rr.unique_order_count
FROM 
    RankedReturns rr
WHERE 
    rr.rank <= 3
ORDER BY 
    rr.total_return_amt DESC;
