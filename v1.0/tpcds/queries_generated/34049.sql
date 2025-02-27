
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
),
BestStores AS (
    SELECT 
        sh.s_store_sk,
        sh.total_profit,
        sh.total_sales,
        s_store_name,
        ROW_NUMBER() OVER (ORDER BY sh.total_profit DESC) AS profit_rank,
        ROW_NUMBER() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        SalesHierarchy sh
    JOIN 
        store s ON sh.s_store_sk = s.s_store_sk
)
SELECT 
    bs.s_store_sk,
    bs.s_store_name,
    bs.total_profit,
    bs.total_sales,
    COALESCE(sm.sm_type, 'N/A') AS shipping_mode,
    (SELECT COUNT(DISTINCT c.c_customer_sk)
     FROM customer c 
     WHERE c.c_current_addr_sk IS NOT NULL) AS customer_count,
    CASE 
        WHEN bs.total_profit > (SELECT AVG(total_profit) FROM SalesHierarchy) THEN 'Above Average'
        ELSE 'Below Average'
    END AS profit_status
FROM 
    BestStores bs
LEFT JOIN 
    ship_mode sm ON bs.s_store_sk = sm.sm_ship_mode_sk
WHERE 
    bs.profit_rank <= 5 OR bs.sales_rank <= 5
ORDER BY 
    bs.total_profit DESC;
