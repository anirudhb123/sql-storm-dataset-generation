
WITH RECURSIVE SalesCTE AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        1 AS level
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk = (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)
    GROUP BY 
        cs_item_sk

    UNION ALL

    SELECT 
        s.ss_item_sk,
        SUM(s.ss_quantity) + c.total_sales AS total_sales,
        SUM(s.ss_net_profit) + c.total_profit AS total_profit,
        c.level + 1
    FROM 
        SalesCTE c
    JOIN 
        store_sales s ON c.cs_item_sk = s.ss_item_sk
    WHERE 
        c.level < 3
    GROUP BY 
        s.ss_item_sk, c.total_sales, c.total_profit, c.level
),
RankedSales AS (
    SELECT 
        i.i_item_id,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_profit, 0) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY COALESCE(s.total_profit, 0) DESC) AS rank
    FROM 
        item i
    LEFT JOIN 
        SalesCTE s ON i.i_item_sk = s.cs_item_sk
)
SELECT 
    r.i_item_id,
    r.total_sales,
    r.total_profit,
    r.rank,
    CASE 
        WHEN r.total_profit IS NULL THEN 'No Profit Data'
        WHEN r.total_profit > 1000 THEN 'High Profit'
        ELSE 'Normal Profit'
    END AS profit_category
FROM 
    RankedSales r
WHERE 
    r.rank <= 10;
