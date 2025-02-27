
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_reason_sk,
        1 AS level
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0

    UNION ALL

    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_reason_sk,
        cr.level + 1
    FROM 
        store_returns sr
    JOIN 
        CustomerReturns cr ON sr.sr_item_sk = cr.sr_item_sk 
    WHERE 
        cr.level < 5
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COUNT(DISTINCT cr.sr_item_sk) AS total_returns,
    SUM(cr.sr_return_quantity) AS total_return_quantity,
    SUM(cr.sr_return_amt) AS total_return_amount,
    SUM(cr.sr_return_tax) AS total_return_tax,
    CASE 
        WHEN SUM(cr.sr_return_amt) > 1000 THEN 'High Value Returner'
        WHEN SUM(cr.sr_return_amt) BETWEEN 500 AND 1000 THEN 'Medium Value Returner'
        ELSE 'Low Value Returner' 
    END AS returner_category,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(cr.sr_return_quantity) DESC) AS rn
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
HAVING 
    total_returns > 0
ORDER BY 
    total_return_amount DESC
LIMIT 10;
