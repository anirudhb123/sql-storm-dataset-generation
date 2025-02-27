
WITH CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS unique_returned_items,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_item_sk) AS unique_returned_items,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
TotalReturns AS (
    SELECT 
        cr.sr_returning_customer_sk AS customer_sk,
        COALESCE(cr.unique_returned_items, 0) + COALESCE(wr.unique_returned_items, 0) AS total_unique_returns,
        COALESCE(cr.total_return_amount, 0) + COALESCE(wr.total_return_amount, 0) AS total_return_value
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.returning_customer_sk = wr.returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(tr.total_unique_returns, 0) AS total_unique_returns,
    COALESCE(tr.total_return_value, 0.00) AS total_return_value,
    DENSE_RANK() OVER (ORDER BY COALESCE(tr.total_return_value, 0) DESC) AS return_value_rank,
    CASE 
        WHEN COALESCE(tr.total_return_value, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(tr.total_return_value, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS return_value_category
FROM 
    customer c
LEFT JOIN 
    TotalReturns tr ON c.c_customer_sk = tr.customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
    AND (EXISTS (
            SELECT 1
            FROM store_sales ss
            WHERE ss.ss_customer_sk = c.c_customer_sk
            AND ss.ss_sold_date_sk IN (
                SELECT d_date_sk 
                FROM date_dim 
                WHERE d_year = 2023
            )
        ) OR 
        EXISTS (
            SELECT 1
            FROM web_sales ws
            WHERE ws.ws_ship_customer_sk = c.c_customer_sk
            AND ws.ws_sold_date_sk IN (
                SELECT d_date_sk 
                FROM date_dim 
                WHERE d_year = 2023
            )
        ))
ORDER BY 
    return_value_rank, total_return_value DESC
FETCH FIRST 100 ROWS ONLY;
