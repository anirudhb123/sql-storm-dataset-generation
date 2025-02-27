
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        wr_order_number,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk, wr_item_sk ORDER BY wr_return_quantity DESC) AS rnk
    FROM web_returns
    WHERE wr_return_quantity IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        r.wr_returning_customer_sk,
        r.wr_item_sk,
        r.wr_order_number,
        COALESCE(SUM(r.wr_return_quantity), 0) AS total_returned
    FROM RankedReturns r
    WHERE r.rnk = 1
    GROUP BY r.wr_returning_customer_sk, r.wr_item_sk, r.wr_order_number
),
TopSellingItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > (SELECT AVG(ws_quantity) FROM web_sales)
)
SELECT 
    ca.city AS customer_city,
    ci.total_returned,
    COALESCE(ts.total_sold, 0) AS total_sold,
    CASE 
        WHEN ci.total_returned > 100 THEN 'High Return'
        WHEN ci.total_returned BETWEEN 50 AND 100 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category
FROM CustomerReturns ci
LEFT JOIN TopSellingItems ts ON ci.wr_item_sk = ts.ws_item_sk
JOIN customer c ON c.c_customer_sk = ci.wr_returning_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE ca.ca_city IS NOT NULL
  AND (ci.total_returned IS NOT NULL OR ts.total_sold IS NOT NULL)
ORDER BY customer_city, total_returned DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
