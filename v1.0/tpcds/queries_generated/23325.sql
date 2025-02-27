
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_return_date_sk IS NOT NULL
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        AVG(wr_return_amt) AS avg_return_amt
    FROM 
        web_returns wr
    JOIN 
        customer c ON wr_returning_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(ir.total_sales) AS total_sales,
    SUM(ir.total_profit) AS total_profit,
    COALESCE(SUM(rr.return_quantity), 0) AS total_returned_quantity,
    CASE 
        WHEN AVG(cs.total_returns) IS NULL THEN 'No Returns'
        ELSE AVG(cs.total_returns)::TEXT
    END AS avg_returns_per_customer
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    ItemSales ir ON ir.ws_item_sk IN (SELECT sr_item_sk FROM RankedReturns WHERE return_rank = 1)
LEFT JOIN 
    CustomerStats cs ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND (c.c_birth_year IS NULL OR c.c_birth_year < 1990 OR c.c_birth_year > 2020)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_profit DESC
LIMIT 
    5;
