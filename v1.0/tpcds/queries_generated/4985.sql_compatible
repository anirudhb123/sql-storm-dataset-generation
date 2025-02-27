
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_web_returned,
        SUM(wr_return_amt) AS total_web_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
AggregatedReturns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_returned, 0) AS total_catalog_returned,
        COALESCE(wr.total_web_returned, 0) AS total_web_returned,
        (COALESCE(cr.total_returned, 0) + COALESCE(wr.total_web_returned, 0)) AS combined_total_returns
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        WebReturns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
)
SELECT 
    a.c_customer_id,
    a.total_catalog_returned,
    a.total_web_returned,
    a.combined_total_returns,
    CASE 
        WHEN a.combined_total_returns > 0 THEN 'Returns Exceed Sales'
        ELSE 'Sales Exceed Returns'
    END AS return_status
FROM 
    AggregatedReturns a
JOIN 
    (SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_sales
     FROM 
        web_sales
     GROUP BY 
        ws_bill_customer_sk) sales ON a.c_customer_id = sales.ws_bill_customer_sk
WHERE 
    (a.combined_total_returns > sales.total_sales) OR 
    (sales.total_sales IS NULL AND a.combined_total_returns > 0)
ORDER BY 
    a.combined_total_returns DESC;
