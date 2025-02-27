
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        CAST(s_number_employees AS DECIMAL) / NULLIF(s_floor_space, 0) AS employee_density,
        1 AS level
    FROM 
        store
    WHERE 
        s_floor_space > 0
    
    UNION ALL
    
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_number_employees,
        s.s_floor_space,
        CAST(s.s_number_employees AS DECIMAL) / NULLIF(s.s_floor_space, 0) AS employee_density,
        sh.level + 1
    FROM 
        store AS s
    JOIN 
        SalesHierarchy AS sh ON s.s_store_sk = sh.s_store_sk
    WHERE 
        sh.level < 5
),
TotalReturns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
StoreSalesSummary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS sales_count
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)
SELECT 
    sh.s_store_name,
    sh.s_number_employees AS number_employees,
    sh.s_floor_space AS floor_space,
    sh.employee_density,
    COALESCE(tr.total_returns, 0) AS store_total_returns,
    COALESCE(tr.total_return_amount, 0) AS store_total_return_amount,
    COALESCE(ss.total_net_profit, 0) AS total_store_net_profit,
    CASE 
        WHEN ss.sales_count > 0 THEN ROUND(COALESCE(tr.return_count, 0) * 100.0 / ss.sales_count, 2)
        ELSE 0 
    END AS return_percentage,
    ROW_NUMBER() OVER (ORDER BY sh.employee_density DESC) AS rank
FROM 
    SalesHierarchy AS sh
LEFT JOIN 
    TotalReturns AS tr ON sh.s_store_sk = tr.sr_store_sk
LEFT JOIN 
    StoreSalesSummary AS ss ON sh.s_store_sk = ss.ss_store_sk
WHERE 
    sh.employee_density > 0
ORDER BY 
    rank;
