
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
), WebReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        wr_returning_customer_sk,
        wr_return_quantity,
        wr_return_amt,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY wr_returned_date_sk DESC) AS rnk
    FROM 
        web_returns
    WHERE 
        wr_return_quantity > 0
), ReturnSummary AS (
    SELECT 
        coalesce(c.c_customer_id, w.ws_bill_customer_sk) AS customer_id,
        SUM(COALESCE(cr.return_amount, 0) + COALESCE(wr.return_amt, 0)) AS total_return_amt,
        COUNT(DISTINCT cr.returning_customer_sk) AS total_customers,
        AVG(COALESCE(cr.return_quantity, 0) + COALESCE(wr.return_quantity, 0)) AS avg_return_qty
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.sr_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN 
        web_sales w ON wr.wr_returning_customer_sk = w.ws_bill_customer_sk
    GROUP BY 
        customer_id
)
SELECT 
    r.customer_id,
    r.total_return_amt,
    CASE 
        WHEN r.total_customers >= 10 THEN 'High'
        WHEN r.total_customers BETWEEN 5 AND 9 THEN 'Medium'
        ELSE 'Low' 
    END AS customer_return_category,
    CONCAT('Total Returns: $', CAST(r.total_return_amt AS CHAR)) AS return_message
FROM 
    ReturnSummary r
WHERE 
    r.total_return_amt > 1000
ORDER BY 
    r.total_return_amt DESC
LIMIT 50;
