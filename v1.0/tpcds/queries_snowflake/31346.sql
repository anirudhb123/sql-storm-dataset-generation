
WITH RECURSIVE SalesHierarchy AS (
    SELECT ss_item_sk, ss_ticket_number, ss_quantity, ss_net_profit, 1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    UNION ALL
    SELECT ss.ss_item_sk, ss.ss_ticket_number, ss.ss_quantity, 
           (sh.ss_net_profit + ss.ss_net_profit) AS ss_net_profit, 
           sh.level + 1
    FROM store_sales ss
    JOIN SalesHierarchy sh ON ss.ss_item_sk = sh.ss_item_sk AND ss.ss_ticket_number = sh.ss_ticket_number
    WHERE sh.level < 3
),
MaxSales AS (
    SELECT ss_item_sk, SUM(ss_net_profit) AS total_net_profit
    FROM SalesHierarchy
    GROUP BY ss_item_sk
),
RankedSales AS (
    SELECT item.i_item_id, 
           COALESCE(MAX(m.total_net_profit), 0) AS max_profit,
           RANK() OVER (ORDER BY COALESCE(MAX(m.total_net_profit), 0) DESC) AS profit_rank
    FROM item
    LEFT JOIN MaxSales m ON item.i_item_sk = m.ss_item_sk
    GROUP BY item.i_item_id
)
SELECT r.i_item_id, 
       r.max_profit, 
       r.profit_rank,
       (SELECT COUNT(*) 
        FROM RankedSales 
        WHERE max_profit < r.max_profit) AS lower_profit_count,
       (SELECT COUNT(*) 
        FROM RankedSales 
        WHERE profit_rank <= 10) AS top_records_count
FROM RankedSales r
WHERE r.profit_rank <= 50
ORDER BY r.profit_rank;
