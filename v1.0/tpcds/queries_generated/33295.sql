
WITH RECURSIVE SalesHistory AS (
    SELECT 
        ss.sold_date_sk, 
        ss.item_sk, 
        ss.store_sk, 
        ss_net_profit AS profit, 
        1 AS level
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk = (
            SELECT MAX(ss2.sold_date_sk)
            FROM store_sales ss2
        )
    UNION ALL
    SELECT 
        ss.sold_date_sk, 
        ss.item_sk, 
        ss.store_sk, 
        ss.net_profit + sh.profit AS profit, 
        sh.level + 1
    FROM 
        store_sales ss
    JOIN 
        SalesHistory sh ON ss.item_sk = sh.item_sk AND sh.level < 5
    WHERE 
        ss.sold_date_sk < sh.sold_date_sk
),
ProfitRanking AS (
    SELECT 
        sh.store_sk,
        SUM(sh.profit) AS total_profit,
        RANK() OVER (PARTITION BY sh.store_sk ORDER BY SUM(sh.profit) DESC) AS profit_rank
    FROM 
        SalesHistory sh
    GROUP BY 
        sh.store_sk
),
StoreInfo AS (
    SELECT 
        s.store_sk, 
        CONCAT(s.store_name, ' - ', s.city, ', ', s.state) AS store_location, 
        s.number_employees, 
        s.floor_space,
        si.total_profit,
        si.profit_rank
    FROM 
        store s
    LEFT JOIN 
        ProfitRanking si ON s.store_sk = si.store_sk
)
SELECT 
    si.store_location,
    si.total_profit,
    si.profit_rank,
    COALESCE(si.number_employees, 0) as employees,
    CASE 
        WHEN si.total_profit IS NULL THEN 'No Sales'
        WHEN si.total_profit < 10000 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profit_indicator
FROM 
    StoreInfo si
WHERE 
    si.profit_rank IS NOT NULL
ORDER BY 
    si.profit_rank;
