
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_item_sk) AS distinct_returned_items
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_id
),
AggregateReturns AS (
    SELECT 
        cr.c_customer_id,
        cr.return_count,
        cr.total_return_amount,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS rank_by_return_amount
    FROM 
        CustomerReturns cr
)
SELECT 
    a.c_customer_id,
    a.return_count,
    a.total_return_amount,
    CASE 
        WHEN a.rank_by_return_amount <= 10 THEN 'Top 10%'
        ELSE 'Lower 90%'
    END AS return_category,
    COALESCE(c.cd_gender, 'U') AS customer_gender,
    COALESCE(ROUND(avg(sj.ss_sales_price), 2), 0) AS avg_sales_price
FROM 
    AggregateReturns a
LEFT JOIN 
    customer c ON a.c_customer_id = c.c_customer_id
LEFT JOIN 
    store_sales sj ON sj.ss_customer_sk = c.c_customer_sk
WHERE 
    sj.ss_sold_date_sk IS NOT NULL
    AND c.c_current_cdemo_sk IS NOT NULL
GROUP BY 
    a.c_customer_id, 
    a.return_count, 
    a.total_return_amount, 
    a.rank_by_return_amount,
    c.cd_gender
HAVING 
    SUM(sj.ss_quantity) > 0
ORDER BY 
    total_return_amount DESC
LIMIT 100;
