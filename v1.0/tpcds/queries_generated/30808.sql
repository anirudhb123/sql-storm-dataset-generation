
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        0 AS level
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
    
    UNION ALL
    
    SELECT 
        c.c_customer_id,
        sh.total_spent * 1.1 AS total_spent, 
        level + 1
    FROM 
        SalesHierarchy sh
    JOIN 
        customer c ON c.c_customer_id = sh.c_customer_id
    WHERE 
        level < 5
),
SalesSummary AS (
    SELECT 
        s.c_customer_id,
        SUM(s.total_spent) AS aggregate_spent
    FROM 
        SalesHierarchy s
    GROUP BY 
        s.c_customer_id
),
HighSpenders AS (
    SELECT 
        s.c_customer_id,
        s.aggregate_spent,
        ROW_NUMBER() OVER (ORDER BY s.aggregate_spent DESC) AS rank
    FROM 
        SalesSummary s
    WHERE 
        s.aggregate_spent IS NOT NULL
),
StoreReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_return_quantity) AS total_returns,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
WebReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    hs.c_customer_id,
    hs.aggregate_spent,
    COALESCE(sr.total_returns, 0) AS store_return_count,
    COALESCE(wr.total_returns, 0) AS web_return_count,
    (COALESCE(sr.avg_return_amt, 0) + COALESCE(wr.avg_return_amt, 0)) AS combined_avg_return_amt
FROM 
    HighSpenders hs
LEFT JOIN 
    StoreReturns sr ON sr.sr_item_sk = hs.c_customer_id
LEFT JOIN 
    WebReturns wr ON wr.wr_item_sk = hs.c_customer_id
WHERE 
    hs.rank <= 10
ORDER BY 
    hs.aggregate_spent DESC;
