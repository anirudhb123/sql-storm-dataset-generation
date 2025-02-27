
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 500 AND 1000
    GROUP BY 
        ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        MAX(wr.wr_returned_date_sk) AS last_return_date
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity > 0
    GROUP BY 
        wr.wr_returning_customer_sk
),
HighValueReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cr.return_count,
        cr.total_return_amount,
        COALESCE(CASE WHEN cr.total_return_amount > 1000 THEN 'High Value' ELSE 'Standard' END, 'Unknown') AS return_value_category
    FROM 
        CustomerReturns cr
)
SELECT 
    ca.city,
    ca.state,
    RANK() OVER (ORDER BY SUM(r.total_return_amount) DESC) AS city_return_rank,
    COALESCE(MAX(cr.return_value_category), 'No Returns') AS customer_return_value_category,
    SUM(s.total_net_paid) AS total_sales_value
FROM 
    customer_address ca
LEFT JOIN 
    CustomerReturns cr ON ca.ca_address_sk = cr.returning_customer_sk
JOIN 
    DummySales ds ON ds.customer_sk = cr.returning_customer_sk OR ds.customer_sk IS NULL
JOIN 
    RankedSales s ON s.ws_item_sk = ds.item_sk
WHERE 
    ca.city IS NOT NULL 
    AND ca.state IS NOT NULL
GROUP BY 
    ca.city, ca.state
HAVING 
    COUNT(DISTINCT cr.returning_customer_sk) > 5 
    OR MAX(cr.return_count) > 2
ORDER BY 
    city_return_rank, total_sales_value DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
