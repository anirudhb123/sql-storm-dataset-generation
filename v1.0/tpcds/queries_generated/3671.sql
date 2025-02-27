
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_profit DESC) AS rn
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sales_price > 0
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_net_profit,
        COUNT(cs.cs_order_number) AS total_sales_count
    FROM 
        item i
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
)
SELECT 
    ia.ca_state,
    ISNULL(SUM(ifs.total_net_profit), 0) AS total_net_profit,
    AVG(ifs.total_sales_count) AS avg_sales_count,
    COUNT(DISTINCT ifs.i_item_id) AS unique_items_sold,
    DENSE_RANK() OVER (ORDER BY ISNULL(SUM(ifs.total_net_profit), 0) DESC) AS state_rank
FROM 
    customer_address ia
LEFT JOIN 
    (SELECT 
         s.ss_customer_sk, 
         ss_store_sk, 
         is.total_net_profit, 
         is.total_sales_count 
     FROM 
         store_sales s
     JOIN 
         ItemSales is ON s.ss_item_sk = is.i_item_sk
    ) ifs ON ia.ca_address_sk = ifs.ss_store_sk
GROUP BY 
    ia.ca_state
HAVING 
    COUNT(DISTINCT ifs.i_item_id) > 10
ORDER BY 
    state_rank;
