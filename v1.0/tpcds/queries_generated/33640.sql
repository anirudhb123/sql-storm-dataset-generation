
WITH RECURSIVE SalesCTE AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY s_store_sk
    UNION ALL
    SELECT 
        s_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        level + 1
    FROM store_sales
    INNER JOIN SalesCTE ON store_sales.s_store_sk = SalesCTE.s_store_sk
    WHERE ss_sold_date_sk < (SELECT MAX(ss_sold_date_sk) FROM store_sales) - level
    GROUP BY s_store_sk
),
RankedSales AS (
    SELECT 
        s_store_sk,
        total_profit,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM SalesCTE
),
TopStores AS (
    SELECT 
        store.s_store_name,
        RankedSales.total_profit,
        RankedSales.total_sales
    FROM RankedSales
    JOIN store ON store.s_store_sk = RankedSales.s_store_sk
    WHERE RankedSales.profit_rank <= 10
)
SELECT 
    s_store_name,
    total_profit,
    total_sales,
    total_profit / NULLIF(total_sales, 0) AS average_profit_per_sale
FROM TopStores
WHERE average_profit_per_sale > (
    SELECT AVG(total_profit / NULLIF(total_sales, 0))
    FROM TopStores
)
ORDER BY average_profit_per_sale DESC;
