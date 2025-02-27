
WITH RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS rank_web,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(cs.cs_net_profit), 0) DESC) AS rank_catalog,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ss.ss_net_profit), 0) DESC) AS rank_store
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopRanked AS (
    SELECT 
        *,
        GREATEST(rank_web, rank_catalog, rank_store) AS max_rank
    FROM 
        RankedSales
),
FinalAggregates AS (
    SELECT 
        max_rank,
        COUNT(*) AS customer_count,
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_catalog_sales) AS avg_catalog_sales,
        AVG(total_store_sales) AS avg_store_sales
    FROM 
        TopRanked
    GROUP BY 
        max_rank
)
SELECT 
    f.max_rank,
    f.customer_count,
    COALESCE(NULLIF(ROUND(f.avg_web_sales, 2), 0), 'No Web Sales') AS avg_web_sales,
    COALESCE(NULLIF(ROUND(f.avg_catalog_sales, 2), 0), 'No Catalog Sales') AS avg_catalog_sales,
    COALESCE(NULLIF(ROUND(f.avg_store_sales, 2), 0), 'No Store Sales') AS avg_store_sales
FROM 
    FinalAggregates f
WHERE 
    f.max_rank = (SELECT MIN(max_rank) FROM FinalAggregates) 
    OR (SELECT COUNT(*) FROM FinalAggregates WHERE max_rank IS NULL) > 0
ORDER BY 
    f.max_rank;
