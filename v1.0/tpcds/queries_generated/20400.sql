
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '30 days')
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY cr_returning_customer_sk
),
WebSales AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_quantity) AS total_web_quantity,
        AVG(ws_net_paid) AS average_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_ship_customer_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(c.c_customer_id, 'UNKNOWN') AS customer_id,
        COALESCE(cr.total_return_quantity, 0) AS return_quantity,
        COALESCE(ws.total_web_quantity, 0) AS web_quantity,
        ws.average_net_paid,
        CASE 
            WHEN cr.total_return_quantity IS NULL THEN 'No Returns'
            WHEN cr.total_return_quantity > 10 THEN 'Frequent Returner'
            ELSE 'Occasional Returner'
        END AS return_behavior
    FROM CustomerReturns cr
    FULL OUTER JOIN Customer c ON cr.returning_customer_sk = c.c_customer_sk
    LEFT JOIN WebSales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
)
SELECT 
    cb.customer_id,
    cb.return_quantity,
    cb.web_quantity,
    cb.average_net_paid,
    cb.return_behavior,
    RANK() OVER (PARTITION BY cb.return_behavior ORDER BY cb.web_quantity DESC) AS return_rank
FROM CombinedReturns cb
WHERE cb.average_net_paid IS NOT NULL 
      AND cb.average_net_paid > (SELECT AVG(average_net_paid) FROM WebSales)
      AND (cb.return_quantity IS NULL OR cb.return_quantity < 5)
ORDER BY cb.return_rank, cb.customer_id;
