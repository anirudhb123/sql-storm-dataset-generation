
WITH RECURSIVE Sales_History AS (
    SELECT 
        ss_item_sk,
        ss_sold_date_sk,
        ss_quantity,
        ss_net_profit,
        1 AS recursion_level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 365 FROM date_dim)
    
    UNION ALL
    
    SELECT 
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        sh.recursion_level + 1
    FROM 
        store_sales ss
    INNER JOIN 
        Sales_History sh ON ss.ss_item_sk = sh.ss_item_sk 
    WHERE 
        sh.recursion_level < 5 AND
        ss.ss_sold_date_sk < sh.ss_sold_date_sk
),
Aggregate_Sales AS (
    SELECT 
        sh.ss_item_sk,
        SUM(sh.ss_quantity) AS total_quantity,
        SUM(sh.ss_net_profit) AS total_net_profit
    FROM 
        Sales_History sh
    GROUP BY 
        sh.ss_item_sk
),
Item_Details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(a.total_quantity, 0) AS total_quantity,
        COALESCE(a.total_net_profit, 0) AS total_net_profit,
        CASE 
            WHEN a.total_net_profit = 0 THEN 'No Profit'
            WHEN a.total_net_profit > 0 THEN 'Profitable'
            ELSE 'Loss'
        END AS profitability
    FROM 
        item i
    LEFT JOIN 
        Aggregate_Sales a ON i.i_item_sk = a.ss_item_sk
),
Top_Stores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
    HAVING 
        COUNT(DISTINCT ss.ss_ticket_number) > 50
),
Sales_Summary AS (
    SELECT 
        it.i_item_id,
        it.total_quantity,
        it.total_net_profit,
        it.profitability,
        ts.sales_count
    FROM 
        Item_Details it
    JOIN 
        Top_Stores ts ON it.total_quantity > 0 -- Assuming join condition needed adjustment to actual logic
    WHERE 
        ts.sales_count > 100
)
SELECT 
    s.*
FROM 
    Sales_Summary s
ORDER BY 
    s.total_net_profit DESC 
FETCH FIRST 10 ROWS ONLY;
