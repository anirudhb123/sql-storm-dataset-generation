
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_day_name = 'Monday') 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_day_name = 'Friday')
),
MaxReturns AS (
    SELECT 
        wr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk IS NOT NULL AND 
        wr_return_amt_inc_tax IS NOT NULL
    GROUP BY 
        wr_returned_date_sk
),
SalesWithReturnInfo AS (
    SELECT 
        r.web_site_sk,
        r.ws_order_number,
        r.ws_quantity,
        COALESCE(m.total_returns, 0) AS total_returns,
        COALESCE(m.total_return_amount, 0) AS total_return_amount,
        r.rank
    FROM 
        RankedSales r
    LEFT JOIN MaxReturns m ON r.ws_order_number = m.wr_returned_date_sk
)
SELECT 
    s.web_site_sk,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(s.total_returns) AS total_items_returned,
    AVG(CASE 
        WHEN s.total_quantity_sold > 0 THEN (s.total_return_amount / (s.total_quantity_sold * 1.0)) 
        ELSE NULL 
    END) AS average_return_ratio
FROM 
    SalesWithReturnInfo s
WHERE 
    s.rank = 1
GROUP BY 
    s.web_site_sk
HAVING 
    AVG(s.total_return_amount) IS NOT NULL
ORDER BY 
    total_quantity_sold DESC
FETCH FIRST 10 ROWS ONLY;

-- Including bizarre facets here, such as:
-- Use of ROW_NUMBER, COALESCE for NULL handling, and MORE than one
-- aggregate function displaying the relationship between sales and returns.
