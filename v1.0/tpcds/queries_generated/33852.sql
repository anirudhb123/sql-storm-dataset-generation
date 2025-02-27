
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ss.s_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        1 AS level,
        ss.ss_ticket_number
    FROM 
        store_sales ss
    GROUP BY 
        ss.s_store_sk, 
        ss.ss_item_sk, 
        ss.ss_ticket_number
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.ss_item_sk,
        sh.total_sales + ss.ss_sales_price,
        sh.level + 1,
        ss.ss_ticket_number
    FROM 
        SalesHierarchy sh
    JOIN 
        store_sales ss ON sh.s_store_sk = ss.s_store_sk AND sh.ss_item_sk = ss.ss_item_sk
    WHERE 
        sh.level < 5
),
FilteredSales AS (
    SELECT 
        s.s_store_name,
        s.s_state,
        SUM(ss.total_sales) AS cumulative_sales
    FROM 
        SalesHierarchy sh
    JOIN 
        store s ON sh.s_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_name, 
        s.s_state
    HAVING 
        SUM(ss.total_sales) > 1000
),
SalesRanked AS (
    SELECT 
        fs.s_store_name,
        fs.s_state,
        fs.cumulative_sales,
        ROW_NUMBER() OVER (PARTITION BY fs.s_state ORDER BY fs.cumulative_sales DESC) AS sales_rank
    FROM 
        FilteredSales fs
)
SELECT 
    sr.s_store_name,
    sr.s_state,
    sr.cumulative_sales,
    sr.sales_rank,
    CASE 
        WHEN sr.cumulative_sales IS NULL THEN 'No Sales'
        WHEN sr.cumulative_sales > 5000 THEN 'High Sales'
        ELSE 'Medium Sales'
    END AS sales_category
FROM 
    SalesRanked sr
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.s_state, 
    sr.sales_rank;
