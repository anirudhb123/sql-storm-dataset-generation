
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
),
StoreDetails AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        rs.total_quantity,
        rs.total_profit,
        rs.profit_rank
    FROM 
        store s
    JOIN 
        RankedSales rs ON s.s_store_sk = rs.s_store_sk
)
SELECT 
    sd.s_store_id,
    sd.s_store_name,
    sd.s_city,
    sd.s_state,
    sd.s_country,
    CASE 
        WHEN sd.profit_rank = 1 THEN 'Top Performer'
        WHEN sd.profit_rank <= 3 THEN 'High Performer'
        ELSE 'Regular Performer'
    END AS performance_category,
    sd.total_quantity,
    sd.total_profit
FROM 
    StoreDetails sd
WHERE 
    sd.total_profit > (SELECT AVG(total_profit) FROM RankedSales)
ORDER BY 
    sd.total_profit DESC
LIMIT 10;
