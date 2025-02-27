
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        1 AS level,
        ss.ss_net_paid,
        ss.ss_quantity,
        CAST(ss.ss_net_paid AS DECIMAL(15,2)) AS total_sales  
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31')
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.s_city,
        sh.s_state,
        level + 1,
        ss.ss_net_paid,
        ss.ss_quantity,
        sh.total_sales + CAST(ss.ss_net_paid AS DECIMAL(15,2))
    FROM 
        SalesHierarchy sh
    JOIN 
        store_sales ss ON sh.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31')
),
CanceledOrders AS (
    SELECT 
        wr.wr_returning_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
FinalSales AS (
    SELECT 
        sh.s_store_name,
        sh.s_city,
        sh.s_state,
        SUM(sh.total_sales) AS total_sales,
        COALESCE(c.total_returned, 0) AS total_returned,
        SUM(sh.total_sales) - COALESCE(c.total_returned, 0) AS net_sales,
        AVG(sh.ss_quantity) AS avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY sh.s_store_sk ORDER BY SUM(sh.total_sales) DESC) AS rank
    FROM 
        SalesHierarchy sh
    LEFT JOIN 
        CanceledOrders c ON sh.s_store_sk = c.customer_sk
    GROUP BY 
        sh.s_store_name, sh.s_city, sh.s_state, c.total_returned
)
SELECT 
    fs.s_store_name,
    fs.s_city,
    fs.s_state,
    fs.total_sales,
    fs.total_returned,
    fs.net_sales,
    fs.avg_quantity,
    CASE
        WHEN fs.net_sales > 10000 THEN 'High Performer'
        WHEN fs.net_sales BETWEEN 5000 AND 10000 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_category 
FROM 
    FinalSales fs
WHERE 
    fs.rank <= 10
ORDER BY 
    fs.net_sales DESC;
