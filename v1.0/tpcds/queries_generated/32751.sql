
WITH Recursive CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
    UNION ALL
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
RankedReturns AS (
    SELECT 
        cr.cr_returning_customer_sk AS customer_sk,
        COALESCE(cr.total_return_quantity, 0) + COALESCE(wr.total_return_quantity, 0) AS total_quantity,
        COALESCE(cr.total_return_amount, 0) + COALESCE(wr.total_return_amount, 0) AS total_amount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(cr.total_return_quantity, 0) + COALESCE(wr.total_return_quantity, 0) DESC) AS rank
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        (SELECT 
            wr_returning_customer_sk,
            SUM(wr_return_quantity) AS total_return_quantity,
            SUM(wr_return_amt_inc_tax) AS total_return_amount
        FROM 
            web_returns
        GROUP BY 
            wr_returning_customer_sk) wr ON cr.returning_customer_sk = wr_returning_customer_sk
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(rr.total_quantity, 0) AS total_returned_quantity,
    COALESCE(rr.total_amount, 0) AS total_returned_amount,
    rr.rank
FROM 
    customer c
LEFT JOIN 
    RankedReturns rr ON c.c_customer_sk = rr.customer_sk
WHERE 
    rr.rank <= 10 OR rr.total_quantity IS NULL
ORDER BY 
    total_returned_quantity DESC;

-- Benchmark additional performance metrics with a potentially large dataset
SELECT 
    DISTINCT ca_state,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND (ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023))
GROUP BY 
    ca_state
ORDER BY 
    total_customers DESC;
