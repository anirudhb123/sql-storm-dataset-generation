
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_market_id,
        s_number_employees,
        s_floor_space,
        0 AS level
    FROM store
    WHERE s_store_sk = 1
    
    UNION ALL
    
    SELECT 
        s_store_sk,
        s_store_name,
        s_market_id,
        s_number_employees,
        s_floor_space,
        level + 1
    FROM store s
    JOIN SalesHierarchy sh ON s.s_market_id = sh.s_market_id AND s.s_store_sk <> sh.s_store_sk
),
SalesData AS (
    SELECT 
        ss.sold_date_sk,
        ss.store_sk,
        SUM(ss.net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.customer_sk) AS unique_customers
    FROM store_sales ss
    JOIN SalesHierarchy sh ON ss.store_sk = sh.s_store_sk
    WHERE ss.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) 
                              AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ss.sold_date_sk, ss.store_sk
),
AggregateSales AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(sd.total_net_profit) AS total_profit,
        SUM(sd.unique_customers) AS total_customers
    FROM date_dim d
    LEFT JOIN SalesData sd ON d.d_date_sk = sd.sold_date_sk
    GROUP BY d.d_date
)
SELECT 
    CAST(a.sales_date AS DATE) AS sales_date,
    ISNULL(a.total_profit, 0) AS total_profit,
    ISNULL(a.total_customers, 0) AS total_customers,
    ROW_NUMBER() OVER (ORDER BY a.sales_date) AS row_num,
    CASE 
        WHEN a.total_profit > 1000 THEN 'High Profit'
        WHEN a.total_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM AggregateSales a
ORDER BY a.sales_date DESC
LIMIT 100;
