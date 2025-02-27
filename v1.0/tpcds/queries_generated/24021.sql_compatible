
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.return_quantity,
        sr.return_amt,
        RANK() OVER (PARTITION BY sr.item_sk ORDER BY sr.returned_date_sk DESC) AS return_rank
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity IS NOT NULL
),

AggregateWebSales AS (
    SELECT 
        ws.item_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS order_count,
        SUM(CASE WHEN ws.net_paid_inc_ship > 100 THEN 1 ELSE 0 END) AS high_value_orders
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk > 0
    GROUP BY 
        ws.item_sk
)

SELECT 
    ca.city,
    ca.state,
    COUNT(DISTINCT c.customer_sk) AS unique_customers,
    COUNT(DISTINCT wr.order_number) AS web_returns,
    AVG(COALESCE(ar.total_net_profit, 0)) AS avg_net_profit_per_return
FROM 
    customer c
JOIN 
    customer_address ca ON c.current_addr_sk = ca.address_sk
LEFT JOIN 
    web_returns wr ON c.customer_sk = wr.returning_customer_sk
LEFT JOIN 
    AggregateWebSales ar ON wr.item_sk = ar.item_sk
JOIN 
    RankedReturns rr ON rr.customer_sk = c.customer_sk AND rr.return_rank = 1
WHERE 
    ca.city IS NOT NULL 
    AND (ca.state = 'TX' OR (ca.state IS NULL AND ca.country = 'USA'))
GROUP BY 
    ca.city,
    ca.state
HAVING 
    COUNT(DISTINCT wr.order_number) > 0 
    AND COUNT(DISTINCT c.customer_sk) > 5
ORDER BY 
    unique_customers DESC, avg_net_profit_per_return DESC;
