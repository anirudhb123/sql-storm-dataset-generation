
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.refunded_cash,
        c.gender,
        c.marital_status,
        c.education_status,
        d.date,
        d.year,
        w.warehouse_id
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.customer_sk = c.customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON sr.returned_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON sr.warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.year = 2023
        AND sr.return_quantity > 0
        AND sr.return_amt > 0
),
AggregateReturns AS (
    SELECT 
        COUNT(*) AS total_returns,
        SUM(return_quantity) AS total_returned_quantity,
        SUM(return_amt) AS total_returned_amount,
        SUM(refunded_cash) AS total_refunded_cash,
        gender,
        marital_status,
        education_status,
        year
    FROM 
        CustomerReturns
    GROUP BY 
        gender, marital_status, education_status, year
),
ReturnSummary AS (
    SELECT 
        gender,
        marital_status,
        education_status,
        total_returns,
        total_returned_quantity,
        total_returned_amount,
        total_refunded_cash,
        RANK() OVER (PARTITION BY year ORDER BY total_returned_amount DESC) AS rank
    FROM 
        AggregateReturns
)
SELECT 
    gender,
    marital_status,
    education_status,
    total_returns,
    total_returned_quantity,
    total_returned_amount,
    total_refunded_cash
FROM 
    ReturnSummary
WHERE 
    rank <= 10
ORDER BY 
    total_returned_amount DESC;
