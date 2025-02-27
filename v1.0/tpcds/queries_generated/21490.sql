
WITH RankedSales AS (
    SELECT 
        w.warehouse_name,
        ws.sold_date_sk,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    WHERE 
        ws.sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq = 3
        ) 
    GROUP BY 
        w.warehouse_name, ws.sold_date_sk
), 
SalesDetails AS (
    SELECT 
        cs.item_sk,
        cs.order_number,
        SUM(cs.net_profit) AS catalog_profit,
        COUNT(DISTINCT cs.bill_customer_sk) AS unique_customers
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.item_sk, cs.order_number
), 
ReturnStats AS (
    SELECT 
        sr.item_sk,
        SUM(sr.return_quantity) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.item_sk
), 
AggregateData AS (
    SELECT 
        r.item_sk,
        COALESCE(s.total_profit, 0) AS total_profit,
        COALESCE(s.catalog_profit, 0) AS catalog_profit,
        COALESCE(r.total_returns, 0) AS total_returns,
        (COALESCE(r.total_returns, 0) * 1.0 / NULLIF(s.unique_customers, 0)) AS return_ratio
    FROM 
        ReturnStats r
    LEFT JOIN 
        SalesDetails s ON r.item_sk = s.item_sk
)
SELECT 
    a.item_sk,
    a.total_profit,
    a.catalog_profit,
    a.total_returns,
    CASE 
        WHEN a.return_ratio > 0.5 THEN 'High Return'
        WHEN a.return_ratio BETWEEN 0.1 AND 0.5 THEN 'Moderate Return'
        ELSE 'Low Return' 
    END AS return_category,
    DENSE_RANK() OVER (ORDER BY a.total_profit DESC) AS profit_density
FROM 
    AggregateData a
WHERE 
    a.catalog_profit > 0
ORDER BY 
    a.total_profit DESC 
FETCH FIRST 10 ROWS ONLY;
